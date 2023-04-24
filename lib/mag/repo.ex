defmodule Mag.Repo do
  use Ecto.Repo,
    otp_app: :mag,
    adapter: Ecto.Adapters.Postgres
end
