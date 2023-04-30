defmodule Mag.Posts do
  def list_posts() do
    IO.puts("this is getting called")
    posts = :ets.tab2list(:posts)

    posts
    |> Enum.map(fn p ->
      p |> elem(1)
    end)
    |> Enum.filter(fn p ->
      p["fields"]["published"] == true
    end)
    |> Enum.map(fn p ->
      %{
        title: p["fields"]["headline"],
        content: p["fields"]["body"],
        id: p["fields"]["row"],
        image: p["fields"]["image"]
      }
    end)
  end

  def subscribe(email) do
    list =
      ExAirtable.Airtable.List.from_map(%{
        "records" => [
          %{
            "fields" => %{
              "email" => email
            }
          }
        ]
      })

    Mag.Airtable.Subscribers.create(list)
  end
end
