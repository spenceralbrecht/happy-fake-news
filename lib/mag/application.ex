defmodule Mag.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MagWeb.Telemetry,
      # Start the Ecto repository
      # Mag.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Mag.PubSub},
      # Start Finch
      {Finch, name: Mag.Finch},
      # Start the Endpoint (http/https)
      MagWeb.Endpoint
      # Start a worker by calling: Mag.Worker.start_link(arg)
      # {Mag.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mag.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MagWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
