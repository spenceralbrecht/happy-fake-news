defmodule Mag.Airtable.Posts do
  use ExAirtable.Table

  def base,
    do: %ExAirtable.Config.Base{
      id: "appi0Ld74mC8AWiM5",
      api_key: "keyqpQh1V4UmQyI6m"
    }

  def name, do: "articles"
end
