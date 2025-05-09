defmodule Oberon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OberonWeb.Telemetry,
      Oberon.Repo,
      {DNSCluster, query: Application.get_env(:oberon, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:oberon, Oban)},
      {Phoenix.PubSub, name: Oberon.PubSub},
      # Start a worker by calling: Oberon.Worker.start_link(arg)
      # {Oberon.Worker, arg},
      # Start to serve requests, typically the last entry
      OberonWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Oberon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OberonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
