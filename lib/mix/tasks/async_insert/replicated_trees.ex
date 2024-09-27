defmodule Mix.Tasks.AsyncInsert.ReplicatedTrees do
  use Mix.Task

  @shortdoc "Runs the ReplicatedMergeTree simulation"

  @moduledoc """
  Runs the ReplicatedMergeTree simulations.

  ## Command line options

    * `--all` - Runs all simulations (default if no option is provided)
    * `--settings` - Runs the simulation with custom settings
    * `--default` - Runs the simulation with default settings
  """

  def run(args) do
    # Ensure the application is started
    Mix.Task.run("app.start")

    # Parse command-line arguments
    options = parse_args(args)

    # Call the appropriate simulation function based on the options
    cond do
      options[:all] ->
        ClickhouseBehaviours.AsyncInserts.ReplicatedMergeTree.simulate_all()

      options[:settings] ->
        ClickhouseBehaviours.AsyncInserts.ReplicatedMergeTree.simulate_settings()

      options[:default] || options == %{} ->
        ClickhouseBehaviours.AsyncInserts.ReplicatedMergeTree.simulate_default()

      true ->
        Mix.shell().error("Invalid option. Use --all, --settings, or --default.")
    end
  end

  defp parse_args(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [all: :boolean, settings: :boolean, default: :boolean],
        aliases: []
      )

    Enum.into(opts, %{})
  end
end
