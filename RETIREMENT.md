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
runtime is stopped; its account and live deployment remain separately unverified.

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
