defmodule Oberon.Repo do
  use Ecto.Repo,
    otp_app: :oberon,
    adapter: Ecto.Adapters.Postgres
end
