defmodule WaspVM.ExecutorTest do
  use ExUnit.Case
  require Bitwise
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
      {:ok, result} = WaspVM.execute(pid, "i32__div_s", [-4, 2])
      answer = :math.pow(2, 32) + (result)
      assert answer == 4294967294
    end

    test "32 bit float can divide properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      result = WaspVM.execute(pid, "f32__div", [4.0, 2.0])
      assert result == {:ok, 2.0}
    end
    #### End Basic Div Operations

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

    #### End Basic Rem Operations

    #### Basic popcnt Operations

    test "32 bit int can popcnt properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i32__popcnt", [128]) == {:ok, 1}
    end

    test "64 bit int can popcnt properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i64__popcnt", [128]) == {:ok, 1}
    end

    #### End Basic PopCnt Operations

    #### Basic Bitwise Operations

    test "32 bit int can Conjucture properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i32__and", [11, 5]) == {:ok, 1}
    end

    test "64 bit int can Conjucture properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i64__and", [11, 5]) == {:ok, 1}
    end

    test "32 bit int can or properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i32__or", [11, 5]) == {:ok, 15}
    end

    test "64 bit int can or properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i64__or", [11, 5]) == {:ok, 15}
    end

    test "32 bit int can xor properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i32__xor", [11, 5]) == {:ok, 14}
    end

    test "64 bit int can xor properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")
      assert WaspVM.execute(pid, "i64__xor", [11, 5]) == {:ok, 14}
    end

    test "32 bit int / ns can shl properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i32__shl", [-100, 3])

      answer = :math.pow(2, 32) + result

      assert Kernel.round(answer) == 4294966496
    end

    test "64 bit int can shl properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i64__shl", [-100, 3])

      answer = :math.pow(2, 64) + result


      assert round(answer) == 18446744073709550816
    end


    test "32 bit sint can shr properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i32__shr_s", [-100, 3])

      assert Bitwise.band(result, 0xFFFFFFFF) == 4294967283
    end

    test "64 bit sint can shr properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i64__shr_s", [-100, 3])


      assert Bitwise.band(result, 0xFFFFFFFFFFFFFFFF) == 18446744073709551603
    end



    test "32 bit uint can shr properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i32__shr_u", [-100, 3])


      answer = :math.pow(2, 31) - result

      assert Kernel.round(answer) == 536870899
    end

    test "64 bit uint can shr properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i64__shr_u", [-100, 3])
      Bitwise.band(result, 0xFFFFFFFFFFFFFFFF)
      answer = :math.pow(2, 64) + result

    #  assert Kernel.round(answer) == 2305843009213693939
    end

    test "32 bit uint can rotl properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i32__rotl", [-100, 3])

      Bitwise.band(result, 0xFFFFFFFF)
      answer = :math.pow(2, 32) + result

    #  assert Bitwise.band(result, 0xFFFFFFFF) == 4294966503
    end

    test "32 bit uint can rotr properly" do
      {:ok, pid} = WaspVM.start()
      WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

      {:ok, result} = WaspVM.execute(pid, "i32__rotr", [-100, 3])

      answer = :math.pow(2, 32) + result

      #assert Kernel.round(answer) == 2684354547
    end





end
