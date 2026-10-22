"""Read only the existing Fly identity and exact retired app's metadata.

Raw CLI output/errors remain in memory. Public logs contain only booleans,
hashes, the already-public app name and numeric release metadata. Never read
secrets, app logs, databases or customer records; never deploy or mutate.
"""
import hashlib
import json
import os
import subprocess
import sys

APP = "happy-headlines"
EXPECTED_OWNER = "93a85ab15e3047807926698f7d50a9a70b425545261b17a3984e7dbe9a623835"


def digest(value):
    return hashlib.sha256(str(value).encode()).hexdigest()


def read_cli(*args):
    result = subprocess.run(
        ["flyctl", *args], capture_output=True, text=True, timeout=60,
        env={**os.environ, "NO_COLOR": "1"}, check=False,
    )
    if result.returncode:
        raise RuntimeError("provider read failed")
    return json.loads(result.stdout)


def main():
    receipt = {"app": APP, "readOnly": True, "ownerMatch": False, "appMatch": False}
    try:
        if not os.environ.get("FLY_API_TOKEN"):
            raise RuntimeError("missing existing credential")
        identity = read_cli("auth", "whoami", "--json")
        receipt["ownerMatch"] = digest(identity.get("email", "").strip().lower()) == EXPECTED_OWNER
        if not receipt["ownerMatch"]:
            raise RuntimeError("identity mismatch")
        status = read_cli("status", "--app", APP, "--json")
        receipt["appMatch"] = status.get("Name") == APP and status.get("Hostname") == APP + ".fly.dev"
        if not receipt["appMatch"]:
            raise RuntimeError("target mismatch")
        receipt["appIdHash"] = digest(status.get("ID", ""))
        receipt["organizationHash"] = digest(json.dumps(status.get("Organization"), sort_keys=True))
        receipt["deployed"] = status.get("Deployed") is True
        version = status.get("Version")
        receipt["releaseVersion"] = version if isinstance(version, int) else None
        machines = read_cli("machine", "list", "--app", APP, "--json")
        receipt["machineCount"] = len(machines)
        receipt["imageHashes"] = sorted({digest(json.dumps(m.get("image_ref"), sort_keys=True)) for m in machines})
        receipt["machines"] = []
        for machine in machines:
            config = machine.get("config", {})
            receipt["machines"].append({
                "idHash": digest(machine.get("id", "")),
                "configHash": digest(json.dumps(config, sort_keys=True)),
                "state": machine.get("state") if machine.get("state") in ("started", "stopped", "suspended", "created", "destroyed") else "other",
                "cordoned": machine.get("cordoned") is True,
                "rootfsPersist": config.get("rootfs", {}).get("persist"),
                "legacyRootfsPersist": config.get("guest", {}).get("persist_rootfs"),
                "restartPolicy": config.get("restart", {}).get("policy"),
                "hasSchedule": bool(config.get("schedule")),
                "hasStandbys": bool(config.get("standbys")),
                "autoDestroy": config.get("auto_destroy") is True,
                "mountCount": len(config.get("mounts", [])),
                "serviceAutostart": [s.get("autostart") for s in config.get("services", [])],
            })
        receipt["qualified"] = True
    except Exception:
        # Do not print provider errors: they can contain identities or credentials.
        receipt["qualified"] = False
    print(json.dumps(receipt, sort_keys=True))
    return 0 if receipt["qualified"] else 1


if __name__ == "__main__":
    sys.exit(main())
