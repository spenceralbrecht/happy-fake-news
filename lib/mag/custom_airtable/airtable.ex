defmodule Mag.Airtable do
  @pat "patA24OmXyKKCXSal.5335a2dce1c52fd317a508e597bfc1ea1a79581f0ddfdf58f0c1f086a274403a"
  @baseId "appi0Ld74mC8AWiM5"
  @tableIdOrName "tblEkwzbkAeIsUo3u"
  @list_url "https://api.airtable.com/v0/#{@baseId}/#{@tableIdOrName}?sort[0][field]=row&sort[0][direction]=asc"

  def publish(id) do
    IO.puts("setting published to true of id #{id}")
    %{}
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
