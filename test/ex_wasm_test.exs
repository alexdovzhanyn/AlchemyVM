defmodule ExWasmTest do
  use ExUnit.Case
  doctest ExWasm

  test "Opens File File" do
    {status, pid} = ExWasm.bin_open("./addTwo_main.wasm")
    assert Process.alive?(pid) == true
  end

  test "Opens & Streams File" do
    {status, pid} = ExWasm.bin_open("./addTwo_main.wasm")
    ExWasm.bin_stream(pid)
    #assert Process.alive?(pid) == true
  end


end
