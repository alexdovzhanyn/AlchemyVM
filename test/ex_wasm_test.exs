defmodule WaspVMTest do
  use ExUnit.Case
  doctest WaspVM

  test "Opens File File" do
    {status, pid} = WaspVM.bin_open("./addTwo_main.wasm")
    assert Process.alive?(pid) == true
  end

  test "Opens & Streams File" do
    {status, pid} = WaspVM.bin_open("./addTwo_main.wasm")
    WaspVM.bin_stream(pid)
    #assert Process.alive?(pid) == true
  end


end
