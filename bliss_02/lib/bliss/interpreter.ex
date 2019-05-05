defmodule Bliss.Interpreter do
  @moduledoc """
  The actual Bliss (Joy) interpreter.

  Used data structures:

      { data_stack, exec_stack, dict_stack }
  """

  @debug false

  @doc "Creates an initial interpreter state"
  def new(), do: {[], [], []}
  def new(exec), do: {[], exec, []}
  def new(exec, dict), do: {[], exec, dict}

  # The actual interpreter.

  def interpret({_, [], _} = vm), do: vm

  def interpret({data, [top | rest], dict})
      when is_number(top) or is_binary(top) or is_list(top),
      do: interpret(print({[top | data], rest, dict}))

  # Minimal combinator base

  def interpret({[car, _cadr | data], [:k | rest], dict}),
    do: interpret(print({data, ensure_quote(car) ++ rest, dict}))

  def interpret({[car, cadr, caddr | data], [:s | rest], dict}),
    do: interpret(print({data, [[cadr, caddr]] ++ [caddr] ++ ensure_quote(car) ++ rest, dict}))

  # Minimal I/O and definitions

  def interpret({[top | data], [:";" | rest], dict}),
    do: interpret(print({data, rest, [top | dict]}))

  def interpret({[top | data], [:. | rest], dict}),
    do: IO.puts(to_string(top)) && interpret(print({data, rest, dict}))

  # Default case

  def interpret({data, [word | rest], dict}),
    do: interpret(print({data, (word |> find(dict)) ++ rest, dict}))

  # Helpers

  defp find(word, dict) do
    Enum.find(
      dict,
      [:ok, ["word not found: " <> inspect(word), :.]],
      fn [name | _] -> name == word end
    )
    |> Enum.at(1)
  end

  defp ensure_quote([_ | _] = arg), do: arg
  defp ensure_quote(arg), do: [arg]

  defp print({data, exec, _} = args) do
    if @debug do
      IO.puts(
        "#{data |> Enum.reverse() |> inspect() |> String.pad_leading(50)} . #{exec |> inspect()}"
      )
    end

    args
  end
end
