import contextlib
import io
import json
import os
import unittest
from unittest.mock import patch

import fly_retirement_preflight as probe


class PreflightTests(unittest.TestCase):
    def run_probe(self, machine, email="fixture@example.invalid", app=probe.APP, secret_metadata=None):
        status = {"Name": app, "Hostname": probe.APP + ".fly.dev", "ID": "private-app", "Organization": {"name": "private-org"}}
        def read(*args):
            if args[0] == "auth":
                return {"email": email}
            if args[0] == "secrets":
                return [] if secret_metadata is None else secret_metadata
            return [machine] if args[0] == "machine" else status
        output = io.StringIO()
        with patch.dict(os.environ, {"FLY_API_TOKEN": "private-secret"}), patch.object(probe, "EXPECTED_OWNER", probe.digest("fixture@example.invalid")), patch.object(probe, "read_cli", side_effect=read), contextlib.redirect_stdout(output):
            result = probe.main()
        for private in [email, "private-app", "private-org", "private-secret", "private-machine", "private-env"]:
            self.assertNotIn(private, output.getvalue())
        return result, json.loads(output.getvalue())

    def machine(self):
        return {"id": "private-machine", "host_status": "ok", "state": "started", "config": {"image": "private-image", "env": {"PRIVATE": "private-env"}, "services": [{}], "disable_machine_autostart": True}}

    def test_complete_legacy_machine_reports_actual_control(self):
        result, receipt = self.run_probe(self.machine())
        self.assertEqual(result, 0)
        self.assertTrue(receipt["machines"][0]["legacyDisableMachineAutostart"])
        self.assertEqual(receipt["machines"][0]["serviceAutostart"], [None])

    def test_incomplete_or_unreachable_metadata_fails_closed(self):
        for change in [{"config": None}, {"host_status": "unreachable"}, {"incomplete_config": {"image": "partial"}}, {"config": {}}]:
            with self.subTest(change=change):
                result, receipt = self.run_probe({**self.machine(), **change})
                self.assertEqual(result, 1)
                self.assertFalse(receipt["qualified"])

    def test_identity_and_target_mismatch_fail_closed(self):
        self.assertEqual(self.run_probe(self.machine(), email="wrong@example.invalid")[0], 1)
        self.assertEqual(self.run_probe(self.machine(), app="wrong-app")[0], 1)

    def test_storage_metadata_does_not_emit_private_values_or_untrusted_labels(self):
        machine = self.machine()
        machine["image_ref"] = {"labels": {"org.opencontainers.image.revision": "a" * 40, "org.label-schema.vcs-ref": "private-secret", "private-label": "private-env"}}
        machine["config"].update({"init": {"cmd": ["private-secret"]}, "files": [{"raw_value": "private-secret"}], "env": {"DATABASE_URL": "private-secret"}})
        result, receipt = self.run_probe(machine)
        self.assertEqual(result, 0)
        evidence = receipt["machines"][0]
        self.assertEqual(evidence["sourceRevisions"], ["a" * 40])
        self.assertTrue(evidence["hasCustomInit"])
        self.assertTrue(evidence["hasInjectedFiles"])
        self.assertTrue(evidence["hasDatabaseUrlPlainConfigEnvironment"])

    def test_database_secret_is_reported_separately_from_plain_environment(self):
        result, receipt = self.run_probe(self.machine(), secret_metadata=[{"name": "DATABASE_URL", "digest": "private-secret"}])
        self.assertEqual(result, 0)
        self.assertTrue(receipt["hasDatabaseUrlSecret"])
        self.assertFalse(receipt["machines"][0]["hasDatabaseUrlPlainConfigEnvironment"])
        self.assertEqual(self.run_probe(self.machine(), secret_metadata={})[0], 1)


if __name__ == "__main__":
    unittest.main()
