defmodule ClickhouseBehaviours.PillarHelpers do
  def create_connection() do
    connection_string = Application.get_env(:clickhouse_behaviours, :migration_url)

    Pillar.Connection.new(connection_string)
  end

  def drop_table(conn, name) do
    Pillar.query(conn, "DROP TABLE IF EXISTS ch_behaviours.#{name} ON CLUSTER cluster_1S_2R")
  end

  def reset_table(conn, name) do
    Pillar.query(conn, "TRUNCATE TABLE IF EXISTS ch_behaviours.#{name}")
  end
end
