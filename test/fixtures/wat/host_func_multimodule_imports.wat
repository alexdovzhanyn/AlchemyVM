(module
  (import "Math" "add" (func $add (param i32 i32) (result i32)))
  (import "Host" "fill_mem_at_locations" (func $fill_mem_at_locations (param i32 i32)))
  (memory (export "memory1") 1)

  (func (export "add") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    call $add
  )

  (func (export "f0") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    call $fill_mem_at_locations

    get_local 0
    i32.load
    get_local 1
    i32.load
    i32.add
  )
)
