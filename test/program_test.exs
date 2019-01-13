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

  test "Host funcs can interface with Memory API properly" do
    # Load host func fixture
    Code.load_file("test/fixtures/hostfuncs/host.ex")

    {:ok, pid} = WaspVM.start()

    # Create a host func that interfaces with the module's memory

    imports = WaspVM.HostFunction.create_imports(Host)

    WaspVM.load_file(pid, "test/fixtures/wasm/host_func.wasm", imports)

    res = WaspVM.execute(pid, "f0", [])

    IO.inspect res
  end

end
