defmodule Mag.Airtable do
  @pat "patS6lsr8st93cM2M.9d67d8e95fcca556c40936d90bd2fd3335877fd71d26bac689ed76f41ab9f310"
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
            "Bearer #{@pat}"
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
          "Bearer #{@pat}"
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
end
