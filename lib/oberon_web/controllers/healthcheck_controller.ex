defmodule OberonWeb.HealthCheckController do
  use OberonWeb, :controller

  def healthz(conn, _args) do
    conn
    |> put_resp_content_type("text/plain")
    |> resp(:ok, "OK")
  end
end
