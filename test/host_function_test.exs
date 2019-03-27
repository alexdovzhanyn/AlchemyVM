defmodule AlchemyVM.HostFunctionTest do
  use ExUnit.Case
  doctest AlchemyVM

  test "Can define host functions using defhost Macro" do
    defmodule DefhostTest do
      use AlchemyVM.HostFunction

      defhost a_function do
        5 + 5
      end
    end

    assert 10 == DefhostTest.hostfunc("a_function", [], nil)
  end

  test "Host functions can be called from Wasm module correctly" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")

    {:ok, pid} = AlchemyVM.start()

    imports = AlchemyVM.HostFunction.create_imports(Math)

    AlchemyVM.load_file(pid, "test/fixtures/wasm/host_func_math.wasm", imports)

    assert <<55::integer-32-little>> == Math.hostfunc("add", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert <<45::integer-32-little>> == Math.hostfunc("subtract", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert <<250::integer-32-little>> == Math.hostfunc("multiply", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert <<10::integer-32-little>> == Math.hostfunc("divide", [<<5::integer-32-little>>, <<50::integer-32-little>>], nil)
    assert {:ok, _gas, 55} = AlchemyVM.execute(pid, "add", [5, 50])
    assert {:ok, _gas, 45} = AlchemyVM.execute(pid, "subtract", [5, 50])
    assert {:ok, _gas, 250} = AlchemyVM.execute(pid, "multiply", [5, 50])
    assert {:ok, _gas, 10} = AlchemyVM.execute(pid, "divide", [5, 50])
  end

  test "Host funcs with numerical return values add to the stack automatically" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")

    {:ok, pid} = AlchemyVM.start()

    imports = AlchemyVM.HostFunction.create_imports(Math)

    AlchemyVM.load_file(pid, "test/fixtures/wasm/host_func_math.wasm", imports)

    assert {:ok, _gas, 1055} = AlchemyVM.execute(pid, "add_using_return", [5, 50])
  end

  test "Host funcs can interface with Memory API properly" do
    # Load host func fixture
    Code.load_file("test/fixtures/hostfuncs/host.ex")

    {:ok, pid} = AlchemyVM.start()

    # Create imports based on modules that implement `defhost` macro calls
    imports = AlchemyVM.HostFunction.create_imports(Host)
    # The above gets expanded to:
    # %{
    #   "Host" => %{
    #     "function0" => #Function<2.119791151/2 in AlchemyVM.HostFunction.create_import/1>
    #   }
    # }

    AlchemyVM.load_file(pid, "test/fixtures/wasm/host_func.wasm", imports)

    assert {:ok, _gas, 10_000_000} = AlchemyVM.execute(pid, "f0", [])
  end

  test "Imports can be generated using more than one module" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")
    Code.load_file("test/fixtures/hostfuncs/host.ex")

    {:ok, pid} = AlchemyVM.start()

    imports = AlchemyVM.HostFunction.create_imports([Math, Host])

    AlchemyVM.load_file(pid, "test/fixtures/wasm/host_func_multimodule_imports.wasm", imports)

    assert {:ok, _gas, 55} = AlchemyVM.execute(pid, "add", [5, 50])
    assert {:ok, _gas, 10_000_000} = AlchemyVM.execute(pid, "f0", [64, 96])
  end

end
