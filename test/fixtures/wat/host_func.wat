(module
  (import "Host" "function0" (func $f0 (param i32 i32))) ;; Function 0 takes no params and returns no value
  (memory (export "memory1") 1) ;; Define and export a memory (only way to access memory from outside)
  (func (export "f0") (result i32) (local i32)
    i32.const 123
    i32.const 8998
    call $f0
    i32.const 0
    i32.load
    set_local 0

    i32.const 32
    i32.load

    get_local 0
    i32.add
  )
)
