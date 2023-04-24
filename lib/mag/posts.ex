defmodule Mag.Posts do
  def list_posts() do
    Mag.Airtable.Posts.list().records
    |> Enum.filter(fn r ->
      r.fields["published"] === true
    end)
    |> Enum.map(fn r ->
      %{
        title: r.fields["headline"],
        content: r.fields["body"],
        image: r.fields["image"]
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

    IO.inspect("list")
    IO.inspect(list)
    Mag.Airtable.Subscribers.create(list)
  end
end
