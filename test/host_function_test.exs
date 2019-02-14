defmodule WaspVM.HostFunctionTest do
  use ExUnit.Case
  doctest WaspVM

  test "Can define host functions using defhost Macro" do
    defmodule DefhostTest do
      use WaspVM.HostFunction

      defhost a_function do
        5 + 5
      end
    end

    assert 10 == DefhostTest.hostfunc("a_function", [], nil)
  end

  test "Host functions can be called from Wasm module correctly" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")

    {:ok, pid} = WaspVM.start()

    imports = WaspVM.HostFunction.create_imports(Math)

    WaspVM.load_file(pid, "test/fixtures/wasm/host_func_math.wasm", imports)

    assert <<55::integer-32-little>> == Math.hostfunc("add", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert <<45::integer-32-little>> == Math.hostfunc("subtract", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert <<250::integer-32-little>> == Math.hostfunc("multiply", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert <<10::integer-32-little>> == Math.hostfunc("divide", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert {:ok, _gas, 55} = WaspVM.execute(pid, "add", [5, 50])
    assert {:ok, _gas, 45} = WaspVM.execute(pid, "subtract", [5, 50])
    assert {:ok, _gas, 250} = WaspVM.execute(pid, "multiply", [5, 50])
    assert {:ok, _gas, 10} = WaspVM.execute(pid, "divide", [5, 50])
  end

  test "Host funcs with numerical return values add to the stack automatically" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")

    {:ok, pid} = WaspVM.start()

    imports = WaspVM.HostFunction.create_imports(Math)

    WaspVM.load_file(pid, "test/fixtures/wasm/host_func_math.wasm", imports)

    assert {:ok, _gas, 1055} = WaspVM.execute(pid, "add_using_return", [5, 50])
  end

  test "Host funcs can interface with Memory API properly" do
    # Load host func fixture
    Code.load_file("test/fixtures/hostfuncs/host.ex")

    {:ok, pid} = WaspVM.start()

    # Create imports based on modules that implement `defhost` macro calls
    imports = WaspVM.HostFunction.create_imports(Host)
    # The above gets expanded to:
    # %{
    #   "Host" => %{
    #     "function0" => #Function<2.119791151/2 in WaspVM.HostFunction.create_import/1>
    #   }
    # }

    WaspVM.load_file(pid, "test/fixtures/wasm/host_func.wasm", imports)

    assert {:ok, _gas, 10_000_000} = WaspVM.execute(pid, "f0", [])
  end

  test "Imports can be generated using more than one module" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")
    Code.load_file("test/fixtures/hostfuncs/host.ex")

    {:ok, pid} = WaspVM.start()

    imports = WaspVM.HostFunction.create_imports([Math, Host])

    WaspVM.load_file(pid, "test/fixtures/wasm/host_func_multimodule_imports.wasm", imports)

    assert {:ok, _gas, 55} = WaspVM.execute(pid, "add", [5, 50])
    assert {:ok, _gas, 10_000_000} = WaspVM.execute(pid, "f0", [64, 96])
  end

end
