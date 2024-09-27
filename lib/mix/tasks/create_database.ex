defmodule Mix.Tasks.CreateDatabase do
  use Mix.Task

  def run(_args) do
    connection_string = Application.get_env(:clickhouse_behaviours, :migration_url)

    Pillar.Connection.new(connection_string)
    |> Pillar.query("CREATE DATABASE IF NOT EXISTS ch_behaviours ON CLUSTER cluster_1S_2R")
  end
end
