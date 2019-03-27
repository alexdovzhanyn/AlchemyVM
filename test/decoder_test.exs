defmodule AlchemyVM.DecoderTest do
  use ExUnit.Case
  doctest AlchemyVM

  test "Can decode basic .wasm" do
    AlchemyVM.Decoder.decode_file("./test/fixtures/wasm/basic_mem_add.wasm")
  end

  test "Can decode large .wasm" do
    AlchemyVM.Decoder.decode_file("./test/fixtures/wasm/blake2b.wasm")
  end


end
