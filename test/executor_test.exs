defmodule WaspVM.ExecutorTest do
  use ExUnit.Case
  require Bitwise
  doctest WaspVM

  #### Basic Int Numeric Operations
  test "32 bit integers with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(6)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__add", [WaspVM.i32(4), WaspVM.i32(2)])
  end

  test "64 bit integers with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(6)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__add", [WaspVM.i64(4), WaspVM.i64(2)])
  end

  test "32 bit integers with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(8)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__mul", [WaspVM.i32(4), WaspVM.i32(2)])
  end

  test "64 bit integers with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(8)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__mul", [WaspVM.i64(4), WaspVM.i64(2)])
  end

  test "32 bit integers with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(-2)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__sub", [WaspVM.i32(4), WaspVM.i32(2)])
  end

  test "64 bit integers with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(-2)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__sub", [WaspVM.i64(4), WaspVM.i64(2)])
  end

  #### END OF Basic Numeric Operations

  #### Basic div Operations

  test "32 bit unsgined int can divide properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(2)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__div_u", [WaspVM.i32(2), WaspVM.i32(4)])
  end

  test "32 bit signed int can divide properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(-2)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__div_s", [WaspVM.i32(2), WaspVM.i32(-4)])
  end

  test "32 bit float can divide properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(2.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__div", [WaspVM.f32(2.0), WaspVM.f32(4.0)])
  end
  #### End Basic Div Operations

  #### Basic REM Operations

  test "32 bit uint can rem properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__rem_u", [WaspVM.i32(2), WaspVM.i32(5)])
  end

  test "64 bit uint can rem properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__rem_u", [WaspVM.i64(2), WaspVM.i64(5)])
  end

  test "32 bit sint can rem properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(-1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__rem_s", [WaspVM.i32(2), WaspVM.i32(-5)])
  end

  test "64 bit sint can rem properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(-1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__rem_s", [WaspVM.i64(2), WaspVM.i64(-5)])
  end

  #### End Basic Rem Operations

  #### Basic popcnt Operations

  test "32 bit int can popcnt properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__popcnt", [WaspVM.i32(128)])
  end

  test "64 bit int can popcnt properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__popcnt", [WaspVM.i64(128)])
  end

  #### End Basic PopCnt  Operations


  #### Basic Bitwise Operations

  test "32 bit int can Conjucture properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__and", [WaspVM.i32(11), WaspVM.i32(5)])
  end

  test "64 bit int can Conjucture properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__and", [WaspVM.i64(11), WaspVM.i64(5)])
  end

  test "32 bit int can or properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(15)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__or", [WaspVM.i32(11), WaspVM.i32(5)])
  end

  test "64 bit int can or properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(15)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__or", [WaspVM.i64(11), WaspVM.i64(5)])
  end

  test "32 bit int can xor properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(14)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__xor", [WaspVM.i32(11), WaspVM.i32(5)])
  end

  test "64 bit int can xor properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(14)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__xor", [WaspVM.i64(11), WaspVM.i64(5)])
  end

  test "32 bit int / ns can shl properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(-800)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__shl", [WaspVM.i32(3), WaspVM.i32(-100)])
  end

  test "64 bit int can shl properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(-800)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__shl", [WaspVM.i64(3), WaspVM.i64(-100)])
  end

  test "32 bit sint can shr properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(-13)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__shr_s", [WaspVM.i32(3), WaspVM.i32(-100)])
  end

  test "64 bit sint can shr properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(-13)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__shr_s", [WaspVM.i64(3), WaspVM.i64(-100)])
  end

  test "32 bit uint can shr properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(12)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__shr_u", [WaspVM.i32(3), WaspVM.i32(100)])
  end

  # NW
  test "64 bit uint can shr properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i64(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__shr_u", [WaspVM.i64(5), WaspVM.i64(6)])
  end

  test "32 bit uint can rotl properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(4294966503)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__rotl", [WaspVM.i32(-100), WaspVM.i32(3)])
  end

  test "32 bit uint can rotr properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(4)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__rotr", [WaspVM.i32(16), WaspVM.i32(2)])
  end


  test "Call instruction works properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/nested_func_call.wasm")

    expected = WaspVM.i32(-7367)
    assert {:ok, _gas, ^expected} =  WaspVM.execute(pid, "nested_func_call", [WaspVM.i32(0), WaspVM.i32(32)])
  end

  ### End simnple BitWise Ops

  ### Begin Float Operations

  test "32 bit float with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(6.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__add", [WaspVM.f32(4.0), WaspVM.f32(2.0)])
  end

  test "64 bit float with add properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(6.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__add", [WaspVM.f64(4.0), WaspVM.f64(2.0)])
  end

  test "32 bit float with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(-2.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__sub", [WaspVM.f32(4.0), WaspVM.f32(2.0)])
  end

  test "64 bit float with sub properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(-2.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__sub", [WaspVM.f64(4.0), WaspVM.f64(2.0)])
  end

  test "32 bit float with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(8.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__mul", [WaspVM.f32(4.0), WaspVM.f32(2.0)])
  end

  test "64 bit float with mult properly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(8.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__mul", [WaspVM.f64(4.0), WaspVM.f64(2.0)])
  end

  test "32 bit Floats Ceil Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(-1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__ceil", [WaspVM.f32(-1.75)])
  end

  test "32 bit Floats Min Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__min", [WaspVM.f32(0.0), WaspVM.f32(0.0)])
  end

  test "32 bit Floats Max Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__max", [WaspVM.f32(0.0), WaspVM.f32(0.0)])
  end

  test "64 bit Floats Min Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__min", [WaspVM.f64(0.0), WaspVM.f64(0.0)])
  end

  test "64 bit Floats Max Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__max", [WaspVM.f64(0.0), WaspVM.f64(0.0)])
  end

  test "32 bit Floats copysign Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__copysign", [WaspVM.f32(0.0), WaspVM.f32(0.0)])
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__copysign", [WaspVM.f32(-1.0), WaspVM.f32(0.0)])

    expected = WaspVM.f32(-1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__copysign", [WaspVM.f32(-1.0), WaspVM.f32(1.0)])
  end

  test "64 bit Floats copysign Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__copysign", [WaspVM.f64(0.0), WaspVM.f64(0.0)])
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__copysign", [WaspVM.f64(-1.0), WaspVM.f64(0.0)])

    expected = WaspVM.f64(-1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__copysign", [WaspVM.f64(-1.0), WaspVM.f64(1.0)])
  end

  test "32 bit Floats abs Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__abs", [WaspVM.f32(0.0)])

    expected = WaspVM.f32(1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__abs", [WaspVM.f32(-1.0)])
  end

  test "64 bit Floats abs Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__abs", [WaspVM.f64(-1.0)])
  end

  test "32 bit Floats neg Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f32(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__neg", [WaspVM.f32(0.0)])

    expected = WaspVM.f32(1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32__neg", [WaspVM.f32(-1.0)])
  end

  test "64 bit Floats neg Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.f64(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__neg", [WaspVM.f64(0.0)])

    expected = WaspVM.f64(1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64__neg", [WaspVM.f64(-1.0)])
  end

  ### End of Basic Float Point Operations

  ### Begin Complex Integer Operations
  test "32 bit Integer lt_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__lt_u", [WaspVM.i32(1), WaspVM.i32(0)])

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__lt_u", [WaspVM.i32(0), WaspVM.i32(1)])
  end

  test "64 bit Integer lt_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__lt_u", [WaspVM.i64(1), WaspVM.i64(0)])

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__lt_u", [WaspVM.i64(0), WaspVM.i64(1)])
  end

  test "32 bit Integer lt_s Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__lt_s", [WaspVM.i32(2), WaspVM.i32(1)])

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__lt_s", [WaspVM.i32(1), WaspVM.i32(2)])
  end

  test "64 bit Integer lt_s Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__lt_s", [WaspVM.i64(2), WaspVM.i64(1)])

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__lt_s", [WaspVM.i64(1), WaspVM.i64(2)])
  end

  test "32 bit Integer gt_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__gt_u", [WaspVM.i32(2), WaspVM.i32(1)])

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__gt_u", [WaspVM.i32(1), WaspVM.i32(2)])
  end

  test "64 bit Integer gt_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__gt_u", [WaspVM.i64(2), WaspVM.i64(1)])

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__gt_u", [WaspVM.i64(1), WaspVM.i64(2)])
  end

  test "32 bit Integer gt_s Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__gt_u", [WaspVM.i32(2), WaspVM.i32(1)])

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__gt_u", [WaspVM.i32(1), WaspVM.i32(2)])
  end

  test "64 bit Integer gt_s Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__gt_s", [WaspVM.i64(2), WaspVM.i64(1)])

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__gt_s", [WaspVM.i64(1), WaspVM.i64(2)])
  end

  test "32 bit Integer le_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__le_u", [WaspVM.i32(2), WaspVM.i32(1)])

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__le_u", [WaspVM.i32(1), WaspVM.i32(2)])
  end

  test "64 bit Integer le_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__le_u", [WaspVM.i64(2), WaspVM.i64(1)])

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__le_u", [WaspVM.i64(1), WaspVM.i64(2)])
  end

  test "32 bit Integer ge_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__ge_u", [WaspVM.i32(2), WaspVM.i32(1)])

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__ge_u", [WaspVM.i32(1), WaspVM.i32(2)])
  end

  test "64 bit Integer ge_u Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__ge_u", [WaspVM.i64(2), WaspVM.i64(1)])

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__ge_u", [WaspVM.i64(1), WaspVM.i64(2)])
  end

  test "32 bit Integer clz Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(6)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__clz", [WaspVM.i32(2)])
  end

  test "64 bit Integer clz Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(6)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__clz", [WaspVM.i64(2)])
  end

  test "32 bit Integer ctz Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(25)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__ctz", [WaspVM.i32(2)])
  end

  test "64 bit Integer ctz Works Correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(57)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64__ctz", [WaspVM.i64(2)])
  end

  ### END COMPLEX INTEGER

  ### BEGIN PARAMETRIC TEST
  test "if statement works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/if_2.wasm")

    expected = WaspVM.i32(1)
    assert {status, _gas, ^expected} = WaspVM.execute(pid, "ifOne", [WaspVM.i32(0)])
  end

  ### END PARAMTERIC TEST

  ### Begin Memory Tests
  test "32 Store 8 works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/memory.wasm")

    expected = WaspVM.i32(4278058235)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_store8", [])
  end

  test "64 Store 8 works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/memory.wasm")

    expected = WaspVM.i64(4278058235)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_store8", [])
  end

  test "32 Store 16 works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/memory.wasm")

    expected = WaspVM.i32(3435907785)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_store16", [])
  end

  test "64 Store 16 works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/memory.wasm")

    expected = WaspVM.i64(3435907785)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_store16", [])
  end

  test "64 Store 32 works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/memory.wasm")

    expected = WaspVM.i64(4294843840)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_store32", [])
  end

  test "32 Store works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/memory.wasm")

    expected = WaspVM.i32(4294843840)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_store", [])
  end

  test "32 load8_s works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i32(-1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_load8_s", [])
  end

  test "32 load8_u works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i32(255)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_load8_u", [])
  end

  test "32 load16_u works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i32(65535)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_load16_u", [])
  end

  test "64 load8_u works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i64(255)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_load8_u", [])
  end

  test "64 load16_u works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i64(65535)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_load16_u", [])
  end

  test "64 load32_u works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i64(4294967295)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_load32_u", [])
  end


  test "32 load16_s works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i32(-1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_load16_s", [])
  end

  test "64 load8_s works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i64(255)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_load8_s", [])
  end

  test "64 load16_s works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i64(65535)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_load16_s", [])
  end

  test "64 load32_s works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/load.wasm")

    expected = WaspVM.i64(4294967295)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_load32_s", [])
  end

  ### End Memory Tests

  ### Begin Wrapping & Trunc Tests
  test "32 wrap 64 works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(4294967295)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_wrap_i64", [])
  end

  test "f32 trunc i32 U works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(3000000000)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_trunc_u_f32", [])
  end

  test "f32 trunc i32 S works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(4294967196)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_trunc_s_f32", [])
  end

  test "f64 trunc i32 U works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(3000000000)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_trunc_u_f64", [])
  end

  test "f64 trunc i32 S works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(4294967196)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32_trunc_s_f64", [])
  end

  test "f32 trunc i64 U works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_trunc_u_f32", [])
  end

  test "f32 trunc i64 S works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_trunc_s_f32", [])
  end

  test "f64 trunc i64 U works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_trunc_u_f64", [])
  end

  test "f64 trunc i64 S works correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_trunc_s_f64", [])
  end

  test "f32 i32 S Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f32(-1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32_convert_s_i32", [])
  end

  test "f32 i32 U Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f32(4294967295.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32_convert_u_i32", [])
  end

  test "f32 i64 S Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f32(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32_convert_s_i64", [])
  end

  test "f32 i64 U Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f32(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32_convert_u_i64", [])
  end

  test "f64 i64 S Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f64(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64_convert_s_i64", [])
  end

  test "f64 i64 U Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f64(0.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64_convert_u_i64", [])
  end

  test "f64 i32 S Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f64(-1.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64_convert_s_i32", [])
  end

  test "f64 i32 U Convert works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f64(4294967295.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64_convert_u_i32", [])
  end

  test "i64 extend i32 u works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.i64(4294967295)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_extend_u_i32", [])
  end

  test "i64 extend i32 s works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.i64(18446744073709551615)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_extend_s_i32", [])
  end

  test "f32 demote f64 works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f32(123456789.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f32_demote_f64", [])
  end

  test "f64 promote f32 works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/wrap_fixed.wasm")

    expected = WaspVM.f64(12345679.0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "f64_demote_f32", [])
  end

  ### End Wrapping & Trunc Tests

  ### Begin Compare tests
  test "i64 eq true works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/compare.wasm")

    expected = WaspVM.i32(1)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_eq_true", [])
  end

  test "i64 eq false works" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/compare.wasm")

    expected = WaspVM.i32(0)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i64_eq_false", [])
  end

  ### END COMPARE

  ### START GAS SYSTEM
  test "gas instantiates correctly" do
    {:ok, pid} = WaspVM.start()
    WaspVM.load_file(pid, "test/fixtures/wasm/types.wasm")

    expected = WaspVM.i32(6)
    assert {:ok, _gas, ^expected} = WaspVM.execute(pid, "i32__add", [WaspVM.i32(2), WaspVM.i32(4)])
  end

  test "gas instantiates with limit correctly" do
    # {:ok, pid} = WaspVM.start()
    #WaspVM.load_file(pid, "test/fixtures/wasm/add_2.wasm")
    #{status, gas_cost, stack_value} =  WaspVM.execute(pid, "_Z3addPi", [4], [gas_limit: 1])
    #{status, gas_cost2, stack_value2} =  WaspVM.execute(pid, "_Z3addPi", [4], [gas_limit: 10])
  #  assert gas_cost == 0
    #assert gas_cost2 == 3
    #assert stack_value == 4
    #assert stack_value2 == 4
  end
end
