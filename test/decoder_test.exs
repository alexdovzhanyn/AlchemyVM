defmodule WaspVM.DecoderTest do
  use ExUnit.Case
  doctest WaspVM

  test "Can decode basic .wasm" do
    WaspVM.Decoder.decode_file("./test/fixtures/wasm/addTwo_main.wasm") |> IO.inspect
  end

  test "Can decode large .wasm" do
    WaspVM.Decoder.decode_file("./test/fixtures/wasm/blake2b.wasm") |> IO.inspect
  end


end
