defmodule Mag.Airtable do
  @baseId "appi0Ld74mC8AWiM5"
  @tableIdOrName "tblEkwzbkAeIsUo3u"
  @list_url "https://api.airtable.com/v0/#{@baseId}/#{@tableIdOrName}?sort[0][field]=row&sort[0][direction]=asc"

  def publish(id) do
    IO.puts("setting published to true of id #{id}")
    url = "https://api.airtable.com/v0/#{@baseId}/#{@tableIdOrName}/#{id}"

    {:ok, _response} =
      Finch.build(
        :patch,
        url,
        [
          {
            "Authorization",
            "Bearer #{personal_access_token!()}"
          },
          {
            "Content-Type",
            "application/json"
          }
        ],
        Jason.encode_to_iodata!(%{
          "fields" => %{
            "published" => true
          }
        })
      )
      |> Finch.request(Mag.Finch)
  end

  def list(offset \\ "") do
    url =
      case offset do
        "" -> @list_url
        _ -> "#{@list_url}&offset=#{offset}"
      end

    IO.puts("calling url #{url}")

    {:ok, response} =
      Finch.build(:get, url, [
        {
          "Authorization",
          "Bearer #{personal_access_token!()}"
        }
      ])
      |> Finch.request(Mag.Finch)

    response_body = Jason.decode!(response.body)

    IO.puts("got #{length(response_body["records"])}")

    response_body
  end

  def list_all() do
    Stream.unfold(list(), fn
      nil ->
        nil

      response ->
        records = response["records"]
        offset = response["offset"]

        case offset do
          nil ->
            {records, nil}

          _ ->
            {records, list(offset)}
        end
    end)
  end

  defp personal_access_token!() do
    case System.get_env("AIRTABLE_PERSONAL_ACCESS_TOKEN") do
      token when is_binary(token) and byte_size(token) > 0 -> token
      _ -> raise "AIRTABLE_PERSONAL_ACCESS_TOKEN must be configured at runtime"
    end
  end
end
