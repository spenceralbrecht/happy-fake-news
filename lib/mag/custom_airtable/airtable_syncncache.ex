defmodule Mag.AirtableSyncAndCache do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    :ets.new(:posts, [:ordered_set, :named_table])
    Process.send_after(self(), :sync, 500)
    {:ok, opts}
  end

  def handle_info(:sync, state) do
    IO.puts("+++++++++RUNNING SYNC+++++++++++++++++")
    fetch()
    schedule(state)
    {:noreply, state}
  end

  defp fetch() do
    posts =
      Mag.Airtable.list_all()
      |> Enum.to_list()
      |> Enum.flat_map(fn r -> r end)

    Enum.each(posts, fn p ->
      :ets.insert(:posts, {p["id"], p})
    end)
  end

  defp schedule(state) do
    IO.puts("Scheduling next sync in #{Keyword.get(state, :sync)}")
    Process.send_after(self(), :sync, Keyword.get(state, :sync))
  end
end
