defmodule Mag.Airtable.Subscribers do
  use ExAirtable.Table

  def base,
    do: %ExAirtable.Config.Base{
      id: "appi0Ld74mC8AWiM5",
      api_key: "keyqpQh1V4UmQyI6m"
    }

  def name, do: "subscribers"
end
