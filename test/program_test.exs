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

    assert {:ok, _gas, -2} = WaspVM.execute(pid, "main", [-4], [trace: true])

    {_status, text} =
      './trace.log'
      |> Path.expand()
      |> Path.absname()
      |> File.read()

    assert String.length(text) > 0

    # Clean up file
    './trace.log'
    |> Path.expand()
    |> Path.absname
    |> File.rm!
  end

  test "Modules with start functions execute immediately after initialization" do
    Code.load_file("test/fixtures/hostfuncs/host.ex")

    {:ok, pid} = WaspVM.start()

    imports = WaspVM.HostFunction.create_imports(Host)

    WaspVM.load_file(pid, "test/fixtures/wasm/start.wasm", imports)

    %{store: %{mems: mems}} = WaspVM.vm_state(pid)

    assert <<15>> =
      mems
      |> hd()
      |> Map.get(:data)
      |> elem(0)
  end
end
