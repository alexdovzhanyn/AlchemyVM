(module
  (import "console" "log" (func $log (param i32)))
  (global $g (import "js" "global") (mut i32))
  (start 1)
  (memory 1)
  (func (export "fill_mem")
  	i32.const 0
    i32.const 1512
    i32.store

    i32.const 32
    i32.const 1121
    i32.store
  )
  (func (export "basic_mem_add") (param i32 i32) (result i32) (local i32)
    get_local 0
    i32.load
    set_local 2
    get_local 1
    i32.load
    get_local 2
    i32.add
  )
)
