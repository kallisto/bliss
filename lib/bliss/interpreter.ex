defmodule Bliss.Interpreter do
  @moduledoc """
  The actual Bliss (Joy) interpreter. Takes parsed input.
  Note about the modes:
  - normal is :RUN mode, i.e. evaluating whatever gets handed in.
  - 'compile' is :LIBRA or :DEFINE mode, they are terminated with a period.
  """

  def new_opts, do: %{mode: :RUN, flags: MapSet.new, hidden: MapSet.new}

  # The actual interpreter.

  @doc "No more elements on the current parsed line. Go back."
  def interpret(opts, [], dict, stack),
    do: {opts, dict, stack}

  @doc "No more elements on the current parsed line. Go back."
  def interpret(opts, [:DBG | tl], dict, stack) do
    IO.puts("Exec:\t#{inspect tl}")
    IO.puts("Dict:\t#{inspect dict}")
    IO.puts("Stack:\t#{inspect stack}")
    IO.puts("Opts:\t#{inspect opts}")
    interpret(opts, tl, dict, stack)
  end

  # Mode switching

  @doc "Start LIBRA mode, mark on stack."
  def interpret(opts, [:LIBRA | tl], dict, stack),
    do: interpret(set_mode(opts, :LIBRA), tl, dict, [:LIBRA | stack])

  @doc "Start LIBRA mode - by way of DEFINE, mark on stack."
  def interpret(opts, [:DEFINE | tl], dict, stack),
    do: interpret(set_mode(opts, :LIBRA), tl, dict, [:LIBRA | stack])

  @doc "End LIBRA."
  def interpret(opts, [:END_LIBRA | tl], dict, stack),
    do: interpret(set_mode(opts, :RUN), tl, dict, Enum.drop_while(stack, &(&1 != :LIBRA)) |> tl())

  # RUN

  @doc "RUN: Invoke elixir from bliss."
  def interpret(%{mode: :RUN} = opts, [:apply | tl], dict, [[module, fun, arity] | stack]) do
    {args, new_stack} = Enum.split(stack, arity)
    new_stack =
      case apply(module, fun, args) do
        args when is_tuple(args) -> Tuple.to_list(args) |> Enum.map(&cast/1)
        args                     -> [cast(args)]
      end
      |> Kernel.++(new_stack)
    interpret(opts, tl, dict, new_stack)
  end

  @doc "RUN: Push the first n elements from the stack to the line interpreter."
  def interpret(%{mode: :RUN} = opts, [:INTPR | tl], dict, [n | stack]) do
    {top, new_stack} = Enum.split(stack, n)
    interpret(opts, top ++ tl, dict, new_stack)
  end

  @doc "RUN: Push non-atom terms on the stack."
  def interpret(%{mode: :RUN} = opts, [hd | tl], dict, stack)
  when not is_atom(hd),
    do: interpret(opts, tl, dict, [hd | stack])

  @doc "RUN: Actually execute stuff."
  def interpret(%{mode: :RUN} = opts, [hd | tl], dict, stack)
  when is_atom(hd) do
    new_line =
      case Map.fetch(dict, hd) do
        {:ok, {_flags, defn}} -> defn ++ tl
        _                     -> raise "Undefined operation: #{inspect(hd)}"
      end
    interpret(opts, new_line, dict, stack)
  end

  # LIBRA / DEFINE

  @doc "LIBRA: Add the hidden flag."
  def interpret(%{mode: :LIBRA} = opts, [:HIDE | tl], dict, stack),
    do: interpret(set_flag(opts, :HIDDEN), tl, dict, stack)

  @doc "LIBRA: Remove the hidden flag."
  def interpret(%{mode: :LIBRA} = opts, [:IN | tl], dict, stack),
    do: interpret(unset_flag(opts, :HIDDEN), tl, dict, stack)

  @doc "LIBRA: Special case: Wrong order of clauses in LIBRA, HIDE."
  def interpret(%{mode: :LIBRA} = opts, [:END, :";" | tl], dict, stack),
    do: interpret(opts, [:";", :END | tl], dict, stack)

  @doc "LIBRA: Special case: Wrong order of clauses in LIBRA, HIDE, END_LIBRA."
  def interpret(%{mode: :LIBRA} = opts, [:END, :"." | tl], dict, stack),
    do: interpret(opts, [:";", :END, :END_LIBRA | tl], dict, stack)

  @doc "LIBRA: End HIDE-IN section. Drop all hidden definitions."
  def interpret(%{mode: :LIBRA} = opts, [:END | tl], dict, stack) do
    {new_opts, new_dict} = clear_hidden(opts, dict)
    interpret(new_opts, tl, new_dict, stack)
  end

  @doc "LIBRA: Syntactic sugar for END_LIBRA."
  def interpret(%{mode: :LIBRA} = opts, [:"." | tl], dict, stack),
    do: interpret(opts, [:";", :END_LIBRA | tl], dict, stack)

  @doc "LIBRA: add a definition to the dict."
  def interpret(%{mode: :LIBRA} = opts, [:";" | tl], dict, stack) do
    {defn, name, rest} =
      stack
      |> Enum.split_while(&(&1 != :==))
      |> case do
        {defn, [:==, name | rest]} when is_atom(name) -> {defn, name, rest}
        {_defn, [:==, name | _rest]}                  -> raise "Bad name (not an atom): #{inspect(name)}"
      end

    opts = if MapSet.member?(opts.flags, :HIDDEN), do: put_hidden(opts, name), else: opts
    interpret(opts, tl,
      add_def(name, defn, opts.flags, opts.hidden, dict),
      Enum.drop_while(rest, &(&1 != :LIBRA)))
  end

  @doc "LIBRA: push intermediate terms on the stack."
  def interpret(%{mode: :LIBRA} = opts, [hd | tl], dict, stack),
    do: interpret(opts, tl, dict, [hd | stack])

  # Helpers.

  defp set_mode(opts, mode), do: %{opts | mode: mode}

  defp set_flag(%{flags: flags} = opts, new_flag),
    do: %{opts | flags: MapSet.put(flags, new_flag)}

  defp unset_flag(%{flags: flags} = opts, old_flag),
    do: %{opts | flags: MapSet.delete(flags, old_flag)}

  defp put_hidden(%{hidden: hidden} = opts, name),
    do: %{opts | hidden: MapSet.put(hidden, name)}

  # Drop all entries marked as hidden in the dict
  defp clear_hidden(%{hidden: hidden} = opts, dict),
    do: {opts |> unset_flag(:HIDDEN) |> Map.put(:hidden, MapSet.new), Map.drop(dict, MapSet.to_list(hidden))}

  # Add operator. New entries have the form {flags :: MapSet, definition :: [_ | _]}
  defp add_def(name, defn, flags, hidden, dict) do
    new_defn =
      Enum.reduce(defn, [], fn (elem, acc) ->
        if MapSet.member?(hidden, elem) do
          {_flags, hidden_def} = Map.get(dict, elem)
          hidden_def ++ acc
        else
          [elem | acc]
        end
      end)
    Map.put(dict, name, {flags, new_defn})
  end

  # Cast to Joy-known datatypes
  defp cast(args) when is_list(args),  do: Enum.map(args, &cast/1)
  defp cast(args) when is_tuple(args), do: Tuple.to_list(args) |> Enum.map(&cast/1)
  defp cast(args) when is_map(args),   do: Map.to_list(args) |> Enum.map(&cast/1)
  defp cast(args),                     do: args
end
