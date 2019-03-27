defmodule AlchemyVM.ProgramTest do
  use ExUnit.Case
  require Bitwise
  doctest AlchemyVM


  test "32 bit div program works properly" do
    {:ok, pid} = AlchemyVM.start()
    AlchemyVM.load_file(pid, "test/fixtures/wasm/int_div.wasm")
    {_status, _gas, result_1} = AlchemyVM.execute(pid, "main", [-4])
    {_status, _gas, result_2} = AlchemyVM.execute(pid, "main", [4])

    assert result_1 == -2
    assert result_2 == 2
  end

  test "Trace Works" do
    {:ok, pid} = AlchemyVM.start()
    AlchemyVM.load_file(pid, "test/fixtures/wasm/int_div.wasm")

    expected = -2
    assert {:ok, _gas, ^expected} = AlchemyVM.execute(pid, "main", [-4], [trace: true])

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

    {:ok, pid} = AlchemyVM.start()

    imports = AlchemyVM.HostFunction.create_imports(Host)

    AlchemyVM.load_file(pid, "test/fixtures/wasm/start.wasm", imports)

    %{store: %{mems: mems}} = AlchemyVM.vm_state(pid)

    assert <<15>> =
      mems
      |> hd()
      |> Map.get(:data)
      |> elem(0)
  end
end
