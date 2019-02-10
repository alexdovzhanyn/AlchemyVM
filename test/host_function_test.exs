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

    assert WaspVM.i32(55) == Math.hostfunc("add", [WaspVM.i32(5), WaspVM.i32(50)], nil)
    assert WaspVM.i32(45) == Math.hostfunc("subtract", [WaspVM.i32(5), WaspVM.i32(50)], nil)
    assert WaspVM.i32(250) == Math.hostfunc("multiply", [WaspVM.i32(5), WaspVM.i32(50)], nil)
    assert WaspVM.i32(10) == Math.hostfunc("divide", [WaspVM.i32(5), WaspVM.i32(50)], nil)

    expected = WaspVM.i32(55)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "add", [WaspVM.i32(5), WaspVM.i32(50)])

    expected = WaspVM.i32(45)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "subtract", [WaspVM.i32(5), WaspVM.i32(50)])

    expected = WaspVM.i32(250)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "multiply", [WaspVM.i32(5), WaspVM.i32(50)])

    expected = WaspVM.i32(10)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "divide", [WaspVM.i32(5), WaspVM.i32(50)])
  end

  test "Host funcs with numerical return values add to the stack automatically" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")

    {:ok, pid} = WaspVM.start()

    imports = WaspVM.HostFunction.create_imports(Math)

    WaspVM.load_file(pid, "test/fixtures/wasm/host_func_math.wasm", imports)

    expected = WaspVM.i32(1055)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "add_using_return", [WaspVM.i32(5), WaspVM.i32(50)])
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

    expected = WaspVM.i32(10_000_000)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f0", [])
  end

  test "Imports can be generated using more than one module" do
    Code.load_file("test/fixtures/hostfuncs/math.ex")
    Code.load_file("test/fixtures/hostfuncs/host.ex")

    {:ok, pid} = WaspVM.start()

    imports = WaspVM.HostFunction.create_imports([Math, Host])

    WaspVM.load_file(pid, "test/fixtures/wasm/host_func_multimodule_imports.wasm", imports)

    expected = WaspVM.i32(55)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "add", [WaspVM.i32(5), WaspVM.i32(50)])

    expected = WaspVM.i32(10_000_000)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f0", [WaspVM.i32(64), WaspVM.i32(96)])
  end

end
