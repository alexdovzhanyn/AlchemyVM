defmodule WaspVMTest do
  use ExUnit.Case
  doctest WaspVM

  test "Opens File File" do
    WaspVM.Decoder.decode_file("./addTwo_main.wasm") |> IO.inspect

  end


end
