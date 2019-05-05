defmodule Bliss do
  @moduledoc false
  import Bliss.Interpreter

  @kernel_file "priv/kernel.bls"
  @external_resource @kernel_file

  @kernel (
    File.read!(@kernel_file)
    |> String.to_charlist
    |> :lexer.string
    |> elem(1)
    |> :parser.parse
    |> elem(1)
    |> (&(interpret(new_opts(), &1, %{}, []))).())

  @doc "Entry point for the CLI"
  def main(_args) do
    {opts, dict, stack} = @kernel
    loop(opts, dict, stack)
  end

  def usage, do: "Usage: bliss (no args)"

  def loop(opts \\ new_opts(), dict \\ %{}, stack \\ []) do
    IO.write("> ")
    line =
      IO.read(:line)
      |> String.to_charlist
      |> :lexer.string
      |> elem(1)
      |> :parser.parse
      |> elem(1)

    {opts, dict, stack} = interpret(opts, line, dict, stack)
    loop(opts, dict, stack)
  end
end
