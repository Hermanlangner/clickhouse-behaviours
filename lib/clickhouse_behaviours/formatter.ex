defmodule Formatter do
  def print_bold_green(text) do
    IO.puts("\e[1m\e[32m#{text}\e[0m")
  end

  def print(text) do
    IO.puts(text)
  end

  def print_separator do
    IO.puts("\e[1m\e[34m#####################################################\e[0m\n")
  end
end
