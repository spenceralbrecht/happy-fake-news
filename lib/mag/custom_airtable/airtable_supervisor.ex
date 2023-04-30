defmodule Mag.AirtableSupervisor do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Mag.AirtableSyncAndCache, [sync: 3600_000]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
