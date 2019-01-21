defmodule WaspVM.ProgramTest do
  use ExUnit.Case
  require Bitwise
  doctest WaspVM


  test "32 bit div program works properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/int_div.wasm")
    {_status, _gas, result_1} = WaspVM.execute(pid, "main", [-4])
    {_status, _gas, result_2} = WaspVM.execute(pid, "main", [4])

    assert result_1 == -2
    assert result_2 == 2
  end

  test "Trace Works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/int_div.wasm")
    {status, gas, result} = WaspVM.execute(pid, "main", [-4], [trace: true])

    {status, text} =
      Path.expand('./trace_log.log')
      |> Path.absname
      |> File.read


    assert String.length(text) > 0

    assert result == -2

    Path.expand('./trace_log.log')
    |> Path.absname
    |> File.rm!

  end

end
