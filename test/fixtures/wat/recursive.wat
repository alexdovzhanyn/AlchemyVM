(module
  (func $re (export "recurse") (param i32) (result i32)
    get_local 0
    i32.const 100
    i32.lt_s
    if (result i32)
      get_local 0
      i32.const 1
      i32.add
      call $re
    else
      get_local 0
    end
  )
)
