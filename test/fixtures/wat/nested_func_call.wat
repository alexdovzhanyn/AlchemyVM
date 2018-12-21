(module
  (memory 1)
  (func $fill_mem
  	i32.const 0
    i32.const 1512
    i32.store

    i32.const 32
    i32.const 1121
    i32.store
  )
  (func $subtract_5000 (param i32) (result i32)
    get_local 0
    i32.const 5000
    i32.sub
  )
  (func (export "nested_func_call") (param i32 i32) (result i32) (local i32)
    call $fill_mem
    get_local 0
    i32.load
    set_local 2
    get_local 1
    i32.load
    get_local 2
    i32.add
    call $subtract_5000
    call $nest1
  )
  (func $nest1 (param i32) (result i32)
    get_local 0
    call $nest2
  )
  (func $nest2 (param i32) (result i32)
    get_local 0
    call $nest3
  )
  (func $nest3 (param i32) (result i32)
    get_local 0
    call $nest4
  )
  (func $nest4 (param i32) (result i32)
    get_local 0
    call $subtract_5000
  )
)
