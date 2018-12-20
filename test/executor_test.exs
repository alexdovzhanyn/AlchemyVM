defmodule WaspVM.ExecutorTest do
  use ExUnit.Case
  doctest WaspVM

  #### Basic Numeric Operations
  test "32 bit integers with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i32__add", [4, 2]) == {:ok, 6}
  end

  test "64 bit integers with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i64__add", [4, 2]) == {:ok, 6}
  end

  test "32 bit float with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "f32__add", [4.0, 2.0]) == {:ok, 6.0}
  end

  test "64 bit float with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "f64__add", [4.0, 2.0]) == {:ok, 6.0}
  end

  test "32 bit integers with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i32__sub", [4, 2]) == {:ok, 2}
  end

  test "64 bit integers with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i64__sub", [4, 2]) == {:ok, 2}
  end

  test "32 bit float with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "f32__sub", [4.0, 2.0]) == {:ok, 2.0}
  end

  test "64 bit float with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "f64__sub", [4.0, 2.0]) == {:ok, 2.0}
  end

  test "32 bit integers with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i32__mul", [4, 2]) == {:ok, 8}
  end

  test "64 bit integers with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "i64__mul", [4, 2]) == {:ok, 8}
  end

  test "32 bit float with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "f32__mul", [4.0, 2.0]) == {:ok, 8.0}
  end

  test "64 bit float with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
    assert WaspVM.execute(pid, "f64__mul", [4.0, 2.0]) == {:ok, 8.0}
  end
    #### END OF Basic Numeric Operations

    #### Basic div Operations
    test "32 bit unsgined int can divide properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      result = WaspVM.execute(pid, "i32__div_u", [4, 2])
      assert result == {:ok, 2}
    end

    test "32 bit signed int can divide properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      result = WaspVM.execute(pid, "i32__div_s", [-4, 2])
      assert result == {:ok, 4294967294}
    end

    #### Basic REM Operations

    test "32 bit uint can rem properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i32__rem_u", [5, 2]) == {:ok, 1}
    end

    test "64 bit uint can rem properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i64__rem_u", [5, 2]) == {:ok, 1}
    end

    test "32 bit sint can rem properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i32__rem_s", [-5, 2]) == {:ok, 4294967295}
    end

    test "64 bit sint can rem properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i64__rem_s", [-5, 2]) == {:ok, 1.8446744073709552e19}
    end

end
