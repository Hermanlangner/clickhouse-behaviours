defmodule ClickhouseBehaviours.AsyncInserts.ReplicatedMergeTree do
  @moduledoc false
  alias ClickhouseBehaviours.PillarHelpers

  defp default_table_name(), do: "replicate_mt_default"
  defp settings_table_name(), do: "replicate_mt_settings"

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
    Formatter.print_bold_green("Simulating ReplicatedMergeTree with default settings \n")

    Formatter.print_bold_green("Inserting record that we expect to always be deduplicated \n")

    insert(conn, default_table_name(), 1, "value_that_should_not_have_duplicates")

    Formatter.print_bold_green("Currently only the record is present \n")

    Formatter.print(fetch_results(conn, default_table_name(), format))

    Formatter.print_bold_green(
      "Inserting dummy value to verify that dedup is not just sequential \n"
    )

    insert(conn, default_table_name(), 2, "dummy_value")

    Formatter.print(fetch_results(conn, default_table_name(), format))
    Formatter.print_bold_green("Inserting initial record again, to ensure no duplicates \n")

    insert(conn, default_table_name(), 1, "value_that_should_not_have_duplicates")

    Formatter.print(fetch_results(conn, default_table_name(), format))

    Formatter.print_bold_green("The record was correctly deduplicated \n")
    Formatter.print_bold_green("Simulation Completed \n")
    Formatter.print_separator()
  end

  defp simulate_settings(conn, format) do
    Formatter.print_separator()

    Formatter.print_bold_green(
      "Simulating ReplicatedMergeTree with replicated_deduplication_window Set to 2 \n"
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

    Formatter.print_bold_green(
      "To ensure we validate behaviours, even though we have limits set low, some behaviours are unpredicatable. We loop through 9000 entries with large strings to force blocks to form. \n"
    )

    Formatter.print_bold_green("This takes a while, please be patient....")

    100..10000
    |> Enum.each(fn x ->
      insert(
        PillarHelpers.create_connection(),
        settings_table_name(),
        1,
        "value_that_should_not_have_duplicates"
      )

      insert(
        PillarHelpers.create_connection(),
        settings_table_name(),
        x,
        "word word word word word word word word word word word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word word word word word word word word word word word word word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word word word word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word wordword word word word word word word word words"
      )
    end)

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
    ENGINE = ReplicatedMergeTree
    ORDER BY id
    """

    create_table_settings = """
    CREATE TABLE IF NOT EXISTS ch_behaviours.#{settings_table_name()} ON CLUSTER cluster_1S_2R
    (
    `id` UInt64,
    `column1` String
    )
    ENGINE = ReplicatedMergeTree
    ORDER BY id
    SETTINGS replicated_deduplication_window = 1,
    replicated_deduplication_window_for_async_inserts = 1,
    replicated_deduplication_window_seconds_for_async_inserts = 1,
    replicated_deduplication_window_seconds = 1, min_merge_bytes_to_use_direct_io = 1
    """

    Pillar.query(conn, create_table_default)
    Pillar.query(conn, create_table_settings)
  end

  defp insert(conn, table_name, id, column1) do
    query = """
    INSERT INTO ch_behaviours.#{table_name} (id, column1)
    SETTINGS async_insert=1, wait_for_async_insert=1, max_insert_block_size=1, async_insert_max_query_number=1, async_insert_max_data_size=1, async_insert_busy_timeout_max_ms=1,async_insert_use_adaptive_busy_timeout=0, async_insert_deduplicate=1
    VALUES (#{id}, '#{column1}')
    """

    Pillar.query(conn, query)
  end

  defp fetch_results(conn, table_name, format) do
    query = """
    SELECT *
    FROM ch_behaviours.#{table_name}
    WHERE id in (1,2,3,4,5,6,7,8,9,10)
    ORDER BY id
     LIMIT 10
    FORMAT #{format}
    """

    {:ok, result} = Pillar.query(conn, query)

    result
  end
end
