defmodule Bliss.InterpreterTest do
  alias Bliss.Interpreter
  use ExUnit.Case
  doctest Bliss

  setup do
    {:ok, [opts: %{mode: :RUN, flags: MapSet.new, hidden: MapSet.new}]}
  end

  test "call elixir code from inside bliss", %{opts: opts} do
    assert Interpreter.interpret(opts, [2, [1, 2, 3], [:'Elixir.Enum', :take, 2], :apply], %{}, []) ==
      {opts, %{}, [[1, 2]]}
  end

  test "assumes LIBRA mode", %{opts: opts} do
    assert Interpreter.interpret(opts, [:LIBRA], %{}, []) ==
      {%{opts | mode: :LIBRA}, %{}, [:LIBRA]}
  end

  test "adds HIDDEN flag in LIBRA mode", %{opts: opts} do
    assert Interpreter.interpret(opts, [:LIBRA, :HIDE], %{}, []) ==
      {%{opts | mode: :LIBRA, flags: MapSet.new([:HIDDEN])}, %{}, [:LIBRA]}
  end

  test "remove HIDDEN flag in LIBRA mode", %{opts: opts} do
    assert Interpreter.interpret(opts, [:LIBRA, :HIDE, :IN], %{}, []) ==
      {%{opts | mode: :LIBRA}, %{}, [:LIBRA]}
    assert Interpreter.interpret(opts, [:LIBRA, :HIDE, :IN, :END], %{}, []) ==
      {%{opts | mode: :LIBRA}, %{}, [:LIBRA]}
  end

  test "define operator in LIBRA mode", %{opts: opts} do
    assert Interpreter.interpret(opts, [:LIBRA, :test, :==, 1, 1, :+, :";"], %{}, []) ==
      {%{opts | mode: :LIBRA}, %{test: {MapSet.new, [1, 1, :+]}}, [:LIBRA]}
  end

  test "define HIDDEN operator in LIBRA mode", %{opts: opts} do
    assert Interpreter.interpret(opts, [:LIBRA, :HIDE, :test, :==, 1, 1, :+, :";", :IN], %{}, []) ==
      {%{opts | mode: :LIBRA, hidden: MapSet.new([:test])}, %{test: {MapSet.new([:HIDDEN]), [1, 1, :+]}}, [:LIBRA]}
  end

  test "use HIDDEN operator in LIBRA mode", %{opts: opts} do
    assert Interpreter.interpret(opts, [:LIBRA, :HIDE, :test, :==, 1, 1, :+, :";", :IN, :test2, :==, :test, 2, :*, :";", :END], %{}, []) ==
      {%{opts | mode: :LIBRA}, %{test2: {MapSet.new, [1, 1, :+, 2, :*]}}, [:LIBRA]}
    # Special case, wrong order of END;
    assert Interpreter.interpret(opts, [:LIBRA, :HIDE, :test, :==, 1, 1, :+, :";", :IN, :test2, :==, :test, 2, :*, :END, :";"], %{}, []) ==
      {%{opts | mode: :LIBRA}, %{test2: {MapSet.new, [1, 1, :+, 2, :*]}}, [:LIBRA]}
  end

  test "LIBRA: end LIBRA mode", %{opts: opts} do
    assert Interpreter.interpret(opts, [:LIBRA, :test, :==, 1, 1, :+, :"."], %{}, []) ==
      {%{opts | mode: :RUN}, %{test: {MapSet.new, [1, 1, :+]}}, []}
  end
end
