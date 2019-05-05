defmodule Bliss do
  @moduledoc false
  alias Bliss.Interpreter

  @kernel_file "priv/kernel.bls"
  @external_resource @kernel_file

  @doc "Entry point for the CLI"
  def main(_args) do
    Interpreter.new() |> loop(File.read!(@kernel_file))
  end

  def usage, do: "Usage: bliss (no args)"

  def load_kernel,
    do: File.read!(@kernel_file) |> parse() |> Interpreter.new() |> Interpreter.interpret()

  defp loop({_, _, dict}, input) do
    input
    |> parse()
    |> Interpreter.new(dict)
    |> Interpreter.interpret()
    |> print()
    |> loop(IO.write("> ") && IO.read(:line))
  end

  defp print({data, exec, dict}) do
    IO.puts(inspect(data) <> " ok.")
    {data, exec, dict}
  end

  defp parse(input) do
    with {:ok, tokens, _} <- :lexer.string(to_charlist(input)),
         {:ok, result} <- :parser.parse(tokens) do
      result
    else
      {:error, reason, _} ->
        IO.puts(reason)

      {:error, {_, :json_parser, reason}} ->
        IO.puts(to_string(reason))
    end
  end
end
