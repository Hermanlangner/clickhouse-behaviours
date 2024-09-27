defmodule ClickhouseBehaviours.AsyncInserts.MergeTree do
  @moduledoc false
  alias ClickhouseBehaviours.PillarHelpers

  defp default_table_name(), do: "merge_tree_default"
  defp settings_table_name(), do: "merge_tree_settings"

  def drop_tables() do
    conn = PillarHelpers.create_connection()
    PillarHelpers.drop_table(conn, default_table_name())
    PillarHelpers.drop_table(conn, settings_table_name())
  end

  def simulate_all(format \\ "PrettyNoEscapesMonoBlock") do
    conn = PillarHelpers.create_connection()
    setup_tables(conn)
    simulate_default(conn, format)
    simulate_settings(conn, format)
  end

  def simulate_default(format \\ "PrettyNoEscapesMonoBlock") do
    conn = PillarHelpers.create_connection()
    setup_tables(conn)
    simulate_default(conn, format)
  end

  def simulate_settings(format \\ "PrettyNoEscapesMonoBlock") do
    conn = PillarHelpers.create_connection()
    setup_tables(conn)
    simulate_settings(conn, format)
  end

  defp simulate_default(conn, format) do
    Formatter.print_separator()
    Formatter.print_bold_green("Simulating MergeTree with default settings \n")

    Formatter.print_bold_green("Inserting record will always have duplicates \n")

    insert(conn, default_table_name(), 1, "value_that_should_have_duplicates")

    Formatter.print(fetch_results(conn, default_table_name(), format))
    Formatter.print_bold_green("Inserting initial record again, will insert a duplicate \n")

    insert(conn, default_table_name(), 1, "value_that_should_have_duplicates")

    Formatter.print(fetch_results(conn, default_table_name(), format))

    Formatter.print_bold_green("Simulation Completed \n")
    Formatter.print_separator()
  end

  defp simulate_settings(conn, format) do
    Formatter.print_separator()

    Formatter.print_bold_green(
      "Simulating ReplicatedMergeTree with non_replicated_deduplication_window Set to 2 \n"
    )

    Formatter.print_bold_green(
      "This should mean that we dedup only when less than 2 other inserts have happened \n"
    )

    Formatter.print_bold_green("Inserting record that we expect to be deduplicated \n")
    insert(conn, settings_table_name(), 1, "value_that_should_not_have_duplicates")
    Formatter.print_bold_green("Currently only the record is present \n")
    Formatter.print(fetch_results(conn, settings_table_name(), format))

    Formatter.print_bold_green(
      "Inserting dummy value to verify that dedup is not just sequential \n"
    )

    insert(conn, settings_table_name(), 2, "dummy_value")
    Formatter.print(fetch_results(conn, settings_table_name(), format))

    Formatter.print_bold_green(
      "Inserting initial record again, Within window, we expect no duplicates \n"
    )

    insert(conn, settings_table_name(), 1, "value_that_should_not_have_duplicates")
    Formatter.print(fetch_results(conn, settings_table_name(), format))

    Formatter.print_bold_green("The record was correctly deduplicated \n")

    Formatter.print_bold_green("Inserting value that should exceed the threshold \n")
    insert(PillarHelpers.create_connection(), settings_table_name(), 3, "threshold_value")

    insert(
      PillarHelpers.create_connection(),
      settings_table_name(),
      1,
      "value_that_should_not_have_duplicates"
    )

    Formatter.print(fetch_results(conn, settings_table_name(), format))

    Formatter.print_bold_green("The record was duplicated \n")

    Formatter.print_bold_green("Simulation Completed \n")
    Formatter.print_separator()
  end

  defp setup_tables(conn) do
    PillarHelpers.reset_table(conn, default_table_name())
    PillarHelpers.reset_table(conn, settings_table_name())

    create_table_default = """
    CREATE TABLE IF NOT EXISTS ch_behaviours.#{default_table_name()} ON CLUSTER cluster_1S_2R
    (
    `id` UInt64,
    `column1` String
    )
    ENGINE = MergeTree
    ORDER BY id
    """

    create_table_settings = """
    CREATE TABLE IF NOT EXISTS ch_behaviours.#{settings_table_name()} ON CLUSTER cluster_1S_2R
    (
    `id` UInt64,
    `column1` String
    )
    ENGINE = MergeTree
    ORDER BY id
    SETTINGS non_replicated_deduplication_window = 2
    """

    Pillar.query(conn, create_table_default)
    Pillar.query(conn, create_table_settings)
  end

  defp insert(conn, table_name, id, column1) do
    query = """
    INSERT INTO ch_behaviours.#{table_name} (id, column1)
    VALUES (#{id}, '#{column1}')
    """

    Pillar.query(conn, query)
  end

  defp fetch_results(conn, table_name, format) do
    query = """
    SELECT *
    FROM ch_behaviours.#{table_name}
    FORMAT #{format}
    """

    {:ok, result} = Pillar.query(conn, query)

    result
  end
end
