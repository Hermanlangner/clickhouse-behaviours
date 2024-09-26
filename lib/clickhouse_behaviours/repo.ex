defmodule ClickhouseBehaviours.Repo do
  use Ecto.Repo,
    otp_app: :clickhouse_behaviours,
    adapter: Ecto.Adapters.Postgres
end
