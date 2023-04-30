defmodule Mag.AirtablePublishJob do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Process.send_after(self(), :publish, Keyword.get(opts, :publish_interval))
    {:ok, opts}
  end

  def handle_info(:publish, state) do
    IO.puts("+++++++++++RUNNING PUBLISH++++++++++++")
    publish()
    schedule(state)
    {:noreply, state}
  end

  def publish() do
    posts = :ets.tab2list(:posts)

    {id, post} =
      posts
      |> Enum.sort(fn a, b ->
        rowA = a |> elem(1)
        rowB = b |> elem(1)
        rowA["fields"]["row"] < rowB["fields"]["row"]
      end)
      |> Enum.find(fn p ->
        row = p |> elem(1)
        row["fields"]["published"] != true
      end)

    :ets.delete(:posts, id)
    post = put_in(post, ["fields", "published"], true)
    :ets.insert(:posts, {id, post})

    Mag.Airtable.publish(id)
  end

  defp schedule(state) do
    IO.puts("Scheduling next publish in #{Keyword.get(state, :publish_interval)}")
    Process.send_after(self(), :publish, Keyword.get(state, :publish_interval))
  end
end
