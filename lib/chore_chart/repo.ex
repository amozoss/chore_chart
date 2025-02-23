defmodule ChoreChart.Repo do
  use Ecto.Repo,
    otp_app: :chore_chart,
    adapter: Ecto.Adapters.Postgres
end
