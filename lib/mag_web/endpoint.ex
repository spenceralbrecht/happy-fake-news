defmodule MagWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mag

  # Retired by the owner. Respond before static files, sockets, sessions, parsers,
  # or application routes can access customer data or external providers.
  plug :retired

  defp retired(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_header("cache-control", "no-store")
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(410, "Happy Headlines has been retired.\n")
    |> Plug.Conn.halt()
  end
end
