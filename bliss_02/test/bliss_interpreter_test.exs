defmodule Bliss.InterpreterTest do
  alias Bliss.Interpreter
  use ExUnit.Case
  doctest Bliss

  setup do
    {:ok, [kernel: Bliss.load_kernel()]}
  end

  test "i - operator", %{kernel: {_, _, dict}} do
    assert Interpreter.interpret({[[1, 2, 3]], [:i], dict}) ==
      {[3, 2, 1], [], dict}
  end
end
