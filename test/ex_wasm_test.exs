defmodule AlchemyVMTest do
  use ExUnit.Case
  doctest AlchemyVM

  # test "Opens File File" do
  #   {status, pid} = AlchemyVM.bin_open("./addTwo_main.wasm")
  #   assert Process.alive?(pid) == true
  # end
  #
  # test "Opens & Streams File" do
  #   {status, pid} = AlchemyVM.bin_open("./addTwo_main.wasm")
  #   AlchemyVM.bin_stream(pid)
  #   #assert Process.alive?(pid) == true
  # end


end
