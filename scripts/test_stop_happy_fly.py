import contextlib
import copy
import io
import json
import os
import unittest
from unittest.mock import patch

import stop_happy_fly as stop


class StopTests(unittest.TestCase):
    def fixture(self):
        config = {"image": "private-image", "env": {"KEY": "private-secret"}, "services": [{"protocol": "tcp"}], "mounts": [], "guest": {"memory_mb": 256}}
        return [{"id": "machine-1", "state": "started", "host_status": "ok", "cordoned": False, "config": copy.deepcopy(config)}, {"id": "machine-2", "state": "stopped", "host_status": "ok", "cordoned": False, "config": copy.deepcopy(config)}]

    def execute(self, fault=None):
        machines = self.fixture()
        config_hash = stop.config_hash(machines[0]["config"])
        status = {"Name": stop.APP, "ID": "private-app", "Organization": {"name": "private-org"}, "Version": 12}
        calls = []
        def read(*args):
            if args[0] == "auth": return {"email": "wrong-owner" if fault == "owner" else "fixture-owner"}
            if args[0] == "status": return status
            return copy.deepcopy(machines)
        def mutate(*args):
            calls.append(args)
            if fault == "provider": raise RuntimeError("private-secret")
            if args[1] == "cordon":
                for machine in machines: machine["cordoned"] = True
            elif args[1] == "stop":
                next(m for m in machines if m["id"] == args[2])["state"] = "stopped"
            elif args[1] == "update":
                target = next(m for m in machines if m["id"] == args[2])
                target["config"]["rootfs"] = {"persist": "always"}
                target["config"]["restart"] = {"policy": "no"}
                target["config"]["services"][0]["autostart"] = False
                if fault == "drift": target["config"]["image"] = "unexpected-image"
            else: self.fail("Unexpected mutation")
        output = io.StringIO()
        with patch.dict(os.environ, {"RETIRE_EXACT_HAPPY_APP": "true"}), patch.object(stop, "EXPECTED_OWNER", stop.digest("fixture-owner")), patch.object(stop, "EXPECTED_APP", stop.digest("private-app")), patch.object(stop, "EXPECTED_ORG", stop.digest(json.dumps(status["Organization"], sort_keys=True))), patch.object(stop, "EXPECTED_IDS", {stop.digest(m["id"]) for m in machines}), patch.object(stop, "EXPECTED_CONFIG", config_hash), patch.object(stop, "read_cli", side_effect=read), patch.object(stop, "mutate", side_effect=mutate), contextlib.redirect_stdout(output):
            result = stop.main()
        for private in ["private-secret", "private-image", "fixture-owner", "private-app", "private-org", "machine-1", "machine-2"]:
            self.assertNotIn(private, output.getvalue())
        return result, calls, json.loads(output.getvalue().splitlines()[-1])

    def test_stop_preserves_config_and_never_deletes_or_starts(self):
        result, calls, receipt = self.execute()
        self.assertEqual(result, 0)
        self.assertTrue(receipt["preservedConfigVerified"])
        self.assertEqual([c[1] for c in calls], ["cordon", "stop", "update", "update"])
        for call in calls:
            if call[1] == "update":
                self.assertIn("--skip-start", call)
                self.assertIn("--autostart=false", call)
                self.assertIn("always", call)

    def test_wrong_owner_never_mutates(self):
        result, calls, _ = self.execute("owner")
        self.assertEqual(result, 1)
        self.assertEqual(calls, [])

    def test_provider_failure_and_unrelated_drift_fail(self):
        for fault in ["provider", "drift"]:
            with self.subTest(fault=fault): self.assertEqual(self.execute(fault)[0], 1)


if __name__ == "__main__":
    unittest.main()
