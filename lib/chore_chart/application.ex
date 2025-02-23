defmodule ChoreChart.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChoreChartWeb.Telemetry,
      ChoreChart.Repo,
      {DNSCluster, query: Application.get_env(:chore_chart, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ChoreChart.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ChoreChart.Finch},
      # Start a worker by calling: ChoreChart.Worker.start_link(arg)
      # {ChoreChart.Worker, arg},
      # Start to serve requests, typically the last entry
      ChoreChartWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChoreChart.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChoreChartWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
