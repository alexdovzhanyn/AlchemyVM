defmodule WaspVMTest do
  use ExUnit.Case
  doctest WaspVM

  test "Opens File File" do
    WaspVM.Decoder.decode_file("./alex.wasm") |> IO.inspect

  end


end
