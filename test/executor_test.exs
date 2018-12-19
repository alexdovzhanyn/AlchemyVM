defmodule WaspVM.ExecutorTest do
  use ExUnit.Case
  doctest WaspVM

  test "unsigned integers with - divide properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i32__div_u", [-4, 2]) == {:ok, 2}
  end

  test "signed integers with - divide properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i32__div_s", [-4, 2]) == {:ok, 0}
  end

  test "unsigned 64 integers with - divide properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i64__div_u", [-4, 2]) == {:ok, 2}
  end

end
