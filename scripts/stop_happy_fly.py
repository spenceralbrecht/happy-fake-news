"""Owner-authorized, reversible retirement of the two verified Fly Machines.

No images, volumes, data, secrets or Machines are deleted. Raw provider output
stays in memory. The original deployment workflow remains disabled.
"""
import copy
import json
import os
import subprocess
import sys

from fly_retirement_preflight import APP, EXPECTED_OWNER, digest, read_cli

EXPECTED_APP = "2d3d382d5fe1cdfbb8da23c53d48e7d94eff9002a355bdcc97fdf6c3787e0f0a"
EXPECTED_ORG = "e22a9376304a2acbc1cc47eac801d2a1914d00023212824b3552673baa853e59"
EXPECTED_IDS = {"375f93615d1e49862787bf9823a64dbd116ae912823a11b70059ea8e7ad21664", "af974afeb16a6004727ef0075b8826b937f9e856c62c8398d7148fb6002ecc01"}
EXPECTED_CONFIG = "d5cf9ce85190559c4439b0efc06173a7050d9fc01dcd75900c7e99a60139ff20"


def config_hash(config):
    return digest(json.dumps(config, sort_keys=True))


def qualify(machines):
    if {digest(m.get("id", "")) for m in machines} != EXPECTED_IDS or len(machines) != 2:
        raise RuntimeError("machine set changed")
    for machine in machines:
        config = machine.get("config")
        if machine.get("host_status") != "ok" or machine.get("incomplete_config") or not isinstance(config, dict):
            raise RuntimeError("incomplete metadata")
        if config.get("auto_destroy") or config.get("schedule") or config.get("standbys"):
            raise RuntimeError("unsafe lifecycle policy")
        original = config_hash(config) == EXPECTED_CONFIG
        restored = preserved_fields(config)
        # Fly serialized the verified original restart policy as {}, not absent.
        # Restore that observed representation before comparing the full hash.
        restored["restart"] = {}
        resumed = desired(config) and config_hash(restored) == EXPECTED_CONFIG
        if machine.get("state") not in ("started", "stopped") or not (original or resumed):
            raise RuntimeError("machine configuration changed")


def preserved_fields(config):
    result = copy.deepcopy(config)
    result.pop("restart", None)
    result.pop("disable_machine_autostart", None)
    rootfs = result.get("rootfs", {})
    rootfs.pop("persist", None)
    if not rootfs:
        result.pop("rootfs", None)
    for service in result.get("services", []):
        service.pop("autostart", None)
    return result


def desired(config):
    return config.get("rootfs", {}).get("persist") == "always" and config.get("restart", {}).get("policy") == "no" and bool(config.get("services")) and all(s.get("autostart") is False for s in config["services"])


def mutate(*args):
    result = subprocess.run(["flyctl", *args], capture_output=True, text=True, timeout=100, check=False)
    if result.returncode:
        raise RuntimeError("provider mutation failed")


def main():
    receipt = {"app": APP, "completed": False, "mutationAttempted": False, "phase": "identity"}
    try:
        if os.environ.get("RETIRE_EXACT_HAPPY_APP") != "true":
            raise RuntimeError("explicit operation required")
        identity = read_cli("auth", "whoami", "--json")
        if digest(identity.get("email", "").strip().lower()) != EXPECTED_OWNER:
            raise RuntimeError("wrong owner")
        status = read_cli("status", "--app", APP, "--json")
        if status.get("Name") != APP or digest(status.get("ID", "")) != EXPECTED_APP or digest(json.dumps(status.get("Organization"), sort_keys=True)) != EXPECTED_ORG or status.get("Version") != 12:
            raise RuntimeError("wrong target or release")
        machines = read_cli("machine", "list", "--app", APP, "--json")
        qualify(machines)
        before = {m["id"]: m for m in machines}
        receipt["rollback"] = [{"idHash": digest(m["id"]), "configHash": config_hash(m["config"]), "state": m["state"], "cordoned": m.get("cordoned", False), "rootfsPersist": m["config"].get("rootfs", {}).get("persist"), "restart": m["config"].get("restart"), "autostart": [s.get("autostart") for s in m["config"].get("services", [])]} for m in machines]
        print(json.dumps({"preflight": receipt}, sort_keys=True), flush=True)
        receipt["phase"] = "cordon"
        receipt["mutationAttempted"] = True
        mutate("machine", "cordon", *before, "--app", APP)
        receipt["phase"] = "preserve-and-disable-restart"
        for machine in machines:
            current = read_cli("machine", "list", "--app", APP, "--json")
            qualify(current)
            target = next(m for m in current if m["id"] == machine["id"])
            if not target.get("cordoned"):
                raise RuntimeError("target changed before update")
            # Apply persistence in the update transition BEFORE a separate stop:
            # default ephemeral write layers can be reset by stopping itself.
            if not desired(target["config"]):
                mutate("machine", "update", machine["id"], "--app", APP, "--rootfs-persist", "always", "--autostart=false", "--restart", "no", "--skip-start", "--yes")
            receipt["phase"] = "verify-persistence"
            protected = read_cli("machine", "list", "--app", APP, "--json")
            qualify(protected)
            target = next(m for m in protected if m["id"] == machine["id"])
            if not desired(target["config"]):
                raise RuntimeError("persistence not confirmed before stop")
            if target["state"] == "started":
                mutate("machine", "stop", machine["id"], "--app", APP, "--signal", "SIGTERM", "--timeout", "30", "--wait-timeout", "60s")
        receipt["phase"] = "readback"
        final = read_cli("machine", "list", "--app", APP, "--json")
        qualify(final)
        for machine in final:
            config = machine.get("config", {})
            if machine.get("host_status") != "ok" or machine.get("incomplete_config"):
                raise RuntimeError("incomplete final metadata")
            if machine["state"] != "stopped" or not machine.get("cordoned") or not desired(config):
                raise RuntimeError("retirement readback failed")
            if preserved_fields(config) != preserved_fields(before[machine["id"]]["config"]):
                raise RuntimeError("unrelated configuration changed")
        receipt["completed"] = True
        receipt["machineCount"] = len(final)
        receipt["preservedConfigVerified"] = True
    except Exception:
        # Never expose raw CLI errors, identities, config values or secrets.
        pass
    print(json.dumps(receipt, sort_keys=True), flush=True)
    return 0 if receipt["completed"] else 1


if __name__ == "__main__":
    sys.exit(main())
