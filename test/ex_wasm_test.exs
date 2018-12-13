defmodule ExWasmTest do
  use ExUnit.Case
  doctest ExWasm

  test "greets the world" do
    assert ExWasm.hello() == :world
  end
end
