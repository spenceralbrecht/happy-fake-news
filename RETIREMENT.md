# Happy Headlines retirement

The owner retired Happy Headlines / Happy Fake News on 2026-10-22. The endpoint
returns HTTP410 before parsers, static assets, LiveView sockets or application
routes. Application startup no longer starts the Airtable polling/publish
supervisor. Source, data, credentials and historical builds are retained.

The exact GitHub Fly deployment workflow (`.github/workflows/elixir.yaml`, ID
56969850) was disabled as retirement governance. Do not re-enable or deploy it
without a verified Fly account/application route and an explicitly authorized
maintenance action. Retirement authority does not authorize reactivation.
GitHub source retirement and repository archival do not prove that the old Fly
runtime is stopped; runtime retirement requires its own provider readback.

The existing GitHub credential subsequently matched the expected owner and exact
`happy-headlines` app (release12, two retained Machines) in read-only run39776768537.
The manual master-only `Retire exact Happy Headlines Fly app` workflow is narrowly
bound to those machine/configuration fingerprints. It cordons them, then applies
rootfs persistence `always`, proxy autostart false and restart policy `no` together
using `--skip-start`. It verifies persistence before any separate graceful stop.
It accepts the exact verified original or fully retired configuration so partial
provider failures can be resumed safely. It checks that all other configuration
is preserved. It does not deploy a new image or delete Machines, volumes or secrets.
`fly.toml` mirrors these retirement controls; the original deploy workflow remains
disabled. Source preparation alone does not prove this manual operation ran.

For authorized recovery, use the verified provider account and retained Machines;
the operation emits prior state/cordon/autostart/restart/rootfs settings under
hashed IDs. Preserve `always` rootfs persistence while recovering data. Reactivating
the old image restores retired behavior and known legacy exposure, so requires a
fresh security and ownership qualification; do not blindly restart or redeploy it.

Validation uses the public repository's read-only `Retirement validation`
workflow: compile the locked dependencies and run `mix run --no-start
test/retirement_smoke.exs` under MIX_ENV=test. This avoids the legacy test alias
that creates/migrates a database; it starts only the retired application and
verifies HTTP410 plus absence of the Airtable pollers. No secrets, Fly deployment,
customer records or paid providers are used.

The separate manual-only `Fly retirement preflight (read only)` workflow can run
only on trusted master. It compares the existing credential's account to the
expected owner's fingerprint, then reads only the exact app's metadata. Public
logs contain booleans/hashes and release numbers, not account details or secrets.
It never deploys, deletes, starts or stops anything.
