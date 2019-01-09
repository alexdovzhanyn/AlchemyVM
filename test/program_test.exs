defmodule WaspVM.ProgramTest do
  use ExUnit.Case
  require Bitwise
  doctest WaspVM


  test "32 bit div program works properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/int_div.wasm")
    {status, gas, result_1} = WaspVM.execute(pid, "main", [-4])
    {status, gas, result_2} = WaspVM.execute(pid, "main", [4])

    assert result_1 == -2
    assert result_2 == 2
  end

end
