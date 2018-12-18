(module
  (func $i32__wrap___i64 (param $arg_0 i64) (result i32)
    (i32.wrap/i64 (get_local $arg_0))
  )
  (export "i32__wrap___i64" (func $i32__wrap___i64))

  (func $i32__trunc_s___f32 (param $arg_0 f32) (result i32)
    (i32.trunc_s/f32 (get_local $arg_0))
  )
  (export "i32__trunc_s___f32" (func $i32__trunc_s___f32))

  (func $i32__trunc_s___f64 (param $arg_0 f64) (result i32)
    (i32.trunc_s/f64 (get_local $arg_0))
  )
  (export "i32__trunc_s___f64" (func $i32__trunc_s___f64))

  (func $i32__trunc_u___f32 (param $arg_0 f32) (result i32)
    (i32.trunc_u/f32 (get_local $arg_0))
  )
  (export "i32__trunc_u___f32" (func $i32__trunc_u___f32))

  (func $i32__trunc_u___f64 (param $arg_0 f64) (result i32)
    (i32.trunc_u/f64 (get_local $arg_0))
  )
  (export "i32__trunc_u___f64" (func $i32__trunc_u___f64))

  (func $i32__reinterpret___f32 (param $arg_0 f32) (result i32)
    (i32.reinterpret/f32 (get_local $arg_0))
  )
  (export "i32__reinterpret___f32" (func $i32__reinterpret___f32))

  (func $i64__extend_s___i32 (param $arg_0 i32) (result i64)
    (i64.extend_s/i32 (get_local $arg_0))
  )
  (export "i64__extend_s___i32" (func $i64__extend_s___i32))

  (func $i64__extend_u___i32 (param $arg_0 i32) (result i64)
    (i64.extend_u/i32 (get_local $arg_0))
  )
  (export "i64__extend_u___i32" (func $i64__extend_u___i32))

  (func $i64__trunc_s___f32 (param $arg_0 f32) (result i64)
    (i64.trunc_s/f32 (get_local $arg_0))
  )
  (export "i64__trunc_s___f32" (func $i64__trunc_s___f32))

  (func $i64__trunc_s___f64 (param $arg_0 f64) (result i64)
    (i64.trunc_s/f64 (get_local $arg_0))
  )
  (export "i64__trunc_s___f64" (func $i64__trunc_s___f64))

  (func $i64__trunc_u___f32 (param $arg_0 f32) (result i64)
    (i64.trunc_u/f32 (get_local $arg_0))
  )
  (export "i64__trunc_u___f32" (func $i64__trunc_u___f32))

  (func $i64__trunc_u___f64 (param $arg_0 f64) (result i64)
    (i64.trunc_u/f64 (get_local $arg_0))
  )
  (export "i64__trunc_u___f64" (func $i64__trunc_u___f64))

  (func $i64__reinterpret___f64 (param $arg_0 f64) (result i64)
    (i64.reinterpret/f64 (get_local $arg_0))
  )
  (export "i64__reinterpret___f64" (func $i64__reinterpret___f64))

  (func $f32__demote___f64 (param $arg_0 f64) (result f32)
    (f32.demote/f64 (get_local $arg_0))
  )
  (export "f32__demote___f64" (func $f32__demote___f64))

  (func $f32__convert_s___i32 (param $arg_0 i32) (result f32)
    (f32.convert_s/i32 (get_local $arg_0))
  )
  (export "f32__convert_s___i32" (func $f32__convert_s___i32))

  (func $f32__convert_s___i64 (param $arg_0 i64) (result f32)
    (f32.convert_s/i64 (get_local $arg_0))
  )
  (export "f32__convert_s___i64" (func $f32__convert_s___i64))

  (func $f32__convert_u___i32 (param $arg_0 i32) (result f32)
    (f32.convert_u/i32 (get_local $arg_0))
  )
  (export "f32__convert_u___i32" (func $f32__convert_u___i32))

  (func $f32__convert_u___i64 (param $arg_0 i64) (result f32)
    (f32.convert_u/i64 (get_local $arg_0))
  )
  (export "f32__convert_u___i64" (func $f32__convert_u___i64))

  (func $f32__reinterpret___i32 (param $arg_0 i32) (result f32)
    (f32.reinterpret/i32 (get_local $arg_0))
  )
  (export "f32__reinterpret___i32" (func $f32__reinterpret___i32))

  (func $f64__promote___f32 (param $arg_0 f32) (result f64)
    (f64.promote/f32 (get_local $arg_0))
  )
  (export "f64__promote___f32" (func $f64__promote___f32))

  (func $f64__convert_s___i32 (param $arg_0 i32) (result f64)
    (f64.convert_s/i32 (get_local $arg_0))
  )
  (export "f64__convert_s___i32" (func $f64__convert_s___i32))

  (func $f64__convert_s___i64 (param $arg_0 i64) (result f64)
    (f64.convert_s/i64 (get_local $arg_0))
  )
  (export "f64__convert_s___i64" (func $f64__convert_s___i64))

  (func $f64__convert_u___i32 (param $arg_0 i32) (result f64)
    (f64.convert_u/i32 (get_local $arg_0))
  )
  (export "f64__convert_u___i32" (func $f64__convert_u___i32))

  (func $f64__convert_u___i64 (param $arg_0 i64) (result f64)
    (f64.convert_u/i64 (get_local $arg_0))
  )
  (export "f64__convert_u___i64" (func $f64__convert_u___i64))

  (func $f64__reinterpret___i64 (param $arg_0 i64) (result f64)
    (f64.reinterpret/i64 (get_local $arg_0))
  )
  (export "f64__reinterpret___i64" (func $f64__reinterpret___i64))

  (func $i32__add (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.add (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__add" (func $i32__add))

  (func $i32__sub (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.sub (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__sub" (func $i32__sub))

  (func $i32__mul (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.mul (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__mul" (func $i32__mul))

  (func $i32__div_s (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.div_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__div_s" (func $i32__div_s))

  (func $i32__div_u (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.div_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__div_u" (func $i32__div_u))

  (func $i32__rem_s (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.rem_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__rem_s" (func $i32__rem_s))

  (func $i32__rem_u (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.rem_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__rem_u" (func $i32__rem_u))

  (func $i32__and (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.and (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__and" (func $i32__and))

  (func $i32__or (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.or (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__or" (func $i32__or))

  (func $i32__xor (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.xor (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__xor" (func $i32__xor))

  (func $i32__shl (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.shl (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__shl" (func $i32__shl))

  (func $i32__shr_u (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.shr_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__shr_u" (func $i32__shr_u))

  (func $i32__shr_s (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.shr_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__shr_s" (func $i32__shr_s))

  (func $i32__rotl (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.rotl (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__rotl" (func $i32__rotl))

  (func $i32__rotr (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.rotr (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__rotr" (func $i32__rotr))

  (func $i32__clz (param $arg_0 i32) (result i32)
    (i32.clz (get_local $arg_0))
  )
  (export "i32__clz" (func $i32__clz))

  (func $i32__ctz (param $arg_0 i32) (result i32)
    (i32.ctz (get_local $arg_0))
  )
  (export "i32__ctz" (func $i32__ctz))

  (func $i32__popcnt (param $arg_0 i32) (result i32)
    (i32.popcnt (get_local $arg_0))
  )
  (export "i32__popcnt" (func $i32__popcnt))

  (func $i32__eq (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.eq (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__eq" (func $i32__eq))

  (func $i32__ne (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.ne (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__ne" (func $i32__ne))

  (func $i32__lt_s (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.lt_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__lt_s" (func $i32__lt_s))

  (func $i32__le_s (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.le_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__le_s" (func $i32__le_s))

  (func $i32__lt_u (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.lt_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__lt_u" (func $i32__lt_u))

  (func $i32__le_u (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.le_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__le_u" (func $i32__le_u))

  (func $i32__gt_s (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.gt_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__gt_s" (func $i32__gt_s))

  (func $i32__ge_s (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.ge_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__ge_s" (func $i32__ge_s))

  (func $i32__gt_u (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.gt_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__gt_u" (func $i32__gt_u))

  (func $i32__ge_u (param $arg_0 i32) (param $arg_1 i32) (result i32)
    (i32.ge_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i32__ge_u" (func $i32__ge_u))

  (func $i32__eqz (param $arg_0 i32) (result i32)
    (i32.eqz (get_local $arg_0))
  )
  (export "i32__eqz" (func $i32__eqz))

  (func $i64__add (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.add (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__add" (func $i64__add))

  (func $i64__sub (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.sub (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__sub" (func $i64__sub))

  (func $i64__mul (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.mul (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__mul" (func $i64__mul))

  (func $i64__div_s (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.div_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__div_s" (func $i64__div_s))

  (func $i64__div_u (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.div_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__div_u" (func $i64__div_u))

  (func $i64__rem_s (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.rem_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__rem_s" (func $i64__rem_s))

  (func $i64__rem_u (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.rem_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__rem_u" (func $i64__rem_u))

  (func $i64__and (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.and (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__and" (func $i64__and))

  (func $i64__or (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.or (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__or" (func $i64__or))

  (func $i64__xor (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.xor (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__xor" (func $i64__xor))

  (func $i64__shl (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.shl (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__shl" (func $i64__shl))

  (func $i64__shr_u (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.shr_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__shr_u" (func $i64__shr_u))

  (func $i64__shr_s (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.shr_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__shr_s" (func $i64__shr_s))

  (func $i64__rotl (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.rotl (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__rotl" (func $i64__rotl))

  (func $i64__rotr (param $arg_0 i64) (param $arg_1 i64) (result i64)
    (i64.rotr (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__rotr" (func $i64__rotr))

  (func $i64__clz (param $arg_0 i64) (result i64)
    (i64.clz (get_local $arg_0))
  )
  (export "i64__clz" (func $i64__clz))

  (func $i64__ctz (param $arg_0 i64) (result i64)
    (i64.ctz (get_local $arg_0))
  )
  (export "i64__ctz" (func $i64__ctz))

  (func $i64__popcnt (param $arg_0 i64) (result i64)
    (i64.popcnt (get_local $arg_0))
  )
  (export "i64__popcnt" (func $i64__popcnt))

  (func $i64__eq (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.eq (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__eq" (func $i64__eq))

  (func $i64__ne (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.ne (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__ne" (func $i64__ne))

  (func $i64__lt_s (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.lt_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__lt_s" (func $i64__lt_s))

  (func $i64__le_s (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.le_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__le_s" (func $i64__le_s))

  (func $i64__lt_u (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.lt_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__lt_u" (func $i64__lt_u))

  (func $i64__le_u (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.le_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__le_u" (func $i64__le_u))

  (func $i64__gt_s (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.gt_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__gt_s" (func $i64__gt_s))

  (func $i64__ge_s (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.ge_s (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__ge_s" (func $i64__ge_s))

  (func $i64__gt_u (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.gt_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__gt_u" (func $i64__gt_u))

  (func $i64__ge_u (param $arg_0 i64) (param $arg_1 i64) (result i32)
    (i64.ge_u (get_local $arg_0) (get_local $arg_1))
  )
  (export "i64__ge_u" (func $i64__ge_u))

  (func $i64__eqz (param $arg_0 i64) (result i32)
    (i64.eqz (get_local $arg_0))
  )
  (export "i64__eqz" (func $i64__eqz))

  (func $f32__add (param $arg_0 f32) (param $arg_1 f32) (result f32)
    (f32.add (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__add" (func $f32__add))

  (func $f32__sub (param $arg_0 f32) (param $arg_1 f32) (result f32)
    (f32.sub (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__sub" (func $f32__sub))

  (func $f32__mul (param $arg_0 f32) (param $arg_1 f32) (result f32)
    (f32.mul (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__mul" (func $f32__mul))

  (func $f32__div (param $arg_0 f32) (param $arg_1 f32) (result f32)
    (f32.div (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__div" (func $f32__div))

  (func $f32__abs (param $arg_0 f32) (result f32)
    (f32.abs (get_local $arg_0))
  )
  (export "f32__abs" (func $f32__abs))

  (func $f32__neg (param $arg_0 f32) (result f32)
    (f32.neg (get_local $arg_0))
  )
  (export "f32__neg" (func $f32__neg))

  (func $f32__copysign (param $arg_0 f32) (param $arg_1 f32) (result f32)
    (f32.copysign (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__copysign" (func $f32__copysign))

  (func $f32__ceil (param $arg_0 f32) (result f32)
    (f32.ceil (get_local $arg_0))
  )
  (export "f32__ceil" (func $f32__ceil))

  (func $f32__floor (param $arg_0 f32) (result f32)
    (f32.floor (get_local $arg_0))
  )
  (export "f32__floor" (func $f32__floor))

  (func $f32__trunc (param $arg_0 f32) (result f32)
    (f32.trunc (get_local $arg_0))
  )
  (export "f32__trunc" (func $f32__trunc))

  (func $f32__nearest (param $arg_0 f32) (result f32)
    (f32.nearest (get_local $arg_0))
  )
  (export "f32__nearest" (func $f32__nearest))

  (func $f32__sqrt (param $arg_0 f32) (result f32)
    (f32.sqrt (get_local $arg_0))
  )
  (export "f32__sqrt" (func $f32__sqrt))

  (func $f32__min (param $arg_0 f32) (param $arg_1 f32) (result f32)
    (f32.min (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__min" (func $f32__min))

  (func $f32__max (param $arg_0 f32) (param $arg_1 f32) (result f32)
    (f32.max (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__max" (func $f32__max))

  (func $f32__eq (param $arg_0 f32) (param $arg_1 f32) (result i32)
    (f32.eq (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__eq" (func $f32__eq))

  (func $f32__ne (param $arg_0 f32) (param $arg_1 f32) (result i32)
    (f32.ne (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__ne" (func $f32__ne))

  (func $f32__lt (param $arg_0 f32) (param $arg_1 f32) (result i32)
    (f32.lt (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__lt" (func $f32__lt))

  (func $f32__le (param $arg_0 f32) (param $arg_1 f32) (result i32)
    (f32.le (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__le" (func $f32__le))

  (func $f32__gt (param $arg_0 f32) (param $arg_1 f32) (result i32)
    (f32.gt (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__gt" (func $f32__gt))

  (func $f32__ge (param $arg_0 f32) (param $arg_1 f32) (result i32)
    (f32.ge (get_local $arg_0) (get_local $arg_1))
  )
  (export "f32__ge" (func $f32__ge))

  (func $f64__add (param $arg_0 f64) (param $arg_1 f64) (result f64)
    (f64.add (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__add" (func $f64__add))

  (func $f64__sub (param $arg_0 f64) (param $arg_1 f64) (result f64)
    (f64.sub (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__sub" (func $f64__sub))

  (func $f64__mul (param $arg_0 f64) (param $arg_1 f64) (result f64)
    (f64.mul (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__mul" (func $f64__mul))

  (func $f64__div (param $arg_0 f64) (param $arg_1 f64) (result f64)
    (f64.div (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__div" (func $f64__div))

  (func $f64__abs (param $arg_0 f64) (result f64)
    (f64.abs (get_local $arg_0))
  )
  (export "f64__abs" (func $f64__abs))

  (func $f64__neg (param $arg_0 f64) (result f64)
    (f64.neg (get_local $arg_0))
  )
  (export "f64__neg" (func $f64__neg))

  (func $f64__copysign (param $arg_0 f64) (param $arg_1 f64) (result f64)
    (f64.copysign (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__copysign" (func $f64__copysign))

  (func $f64__ceil (param $arg_0 f64) (result f64)
    (f64.ceil (get_local $arg_0))
  )
  (export "f64__ceil" (func $f64__ceil))

  (func $f64__floor (param $arg_0 f64) (result f64)
    (f64.floor (get_local $arg_0))
  )
  (export "f64__floor" (func $f64__floor))

  (func $f64__trunc (param $arg_0 f64) (result f64)
    (f64.trunc (get_local $arg_0))
  )
  (export "f64__trunc" (func $f64__trunc))

  (func $f64__nearest (param $arg_0 f64) (result f64)
    (f64.nearest (get_local $arg_0))
  )
  (export "f64__nearest" (func $f64__nearest))

  (func $f64__sqrt (param $arg_0 f64) (result f64)
    (f64.sqrt (get_local $arg_0))
  )
  (export "f64__sqrt" (func $f64__sqrt))

  (func $f64__min (param $arg_0 f64) (param $arg_1 f64) (result f64)
    (f64.min (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__min" (func $f64__min))

  (func $f64__max (param $arg_0 f64) (param $arg_1 f64) (result f64)
    (f64.max (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__max" (func $f64__max))

  (func $f64__eq (param $arg_0 f64) (param $arg_1 f64) (result i32)
    (f64.eq (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__eq" (func $f64__eq))

  (func $f64__ne (param $arg_0 f64) (param $arg_1 f64) (result i32)
    (f64.ne (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__ne" (func $f64__ne))

  (func $f64__lt (param $arg_0 f64) (param $arg_1 f64) (result i32)
    (f64.lt (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__lt" (func $f64__lt))

  (func $f64__le (param $arg_0 f64) (param $arg_1 f64) (result i32)
    (f64.le (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__le" (func $f64__le))

  (func $f64__gt (param $arg_0 f64) (param $arg_1 f64) (result i32)
    (f64.gt (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__gt" (func $f64__gt))

  (func $f64__ge (param $arg_0 f64) (param $arg_1 f64) (result i32)
    (f64.ge (get_local $arg_0) (get_local $arg_1))
  )
  (export "f64__ge" (func $f64__ge))

)
