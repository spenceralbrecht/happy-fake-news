# Run independently of the legacy database test alias/helper. The retired
# application does not start a repository or the Airtable polling workers.
ExUnit.start()
{:ok, _} = Application.ensure_all_started(:mag)

defmodule MagWeb.RetirementSmokeTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "every former request path returns410 before parsing or application work" do
    for method <- [:get, :head, :post, :put, :patch, :delete, :options],
        path <- ["/", "/health", "/subscribe", "/live/websocket", "/assets/app.js", "/unknown"] do
      result =
        conn(method, path, "malformed input")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> MagWeb.Endpoint.call(MagWeb.Endpoint.init([]))

      assert result.status == 410
      assert result.halted
      assert Plug.Conn.get_resp_header(result, "cache-control") == ["no-store"]
      expected_body = if method == :head, do: "", else: "Happy Headlines has been retired.\n"
      assert result.resp_body == expected_body
    end
  end

  test "application startup does not launch Airtable pollers" do
    assert Process.whereis(Mag.AirtableSupervisor) == nil
    assert Process.whereis(Mag.AirtableSyncAndCache) == nil
    assert Process.whereis(Mag.AirtablePublishJob) == nil
  end
end
