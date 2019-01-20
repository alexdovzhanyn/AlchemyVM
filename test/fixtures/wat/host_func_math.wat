(module
  (import "Math" "add" (func $add (param i32 i32) (result i32)))
  (import "Math" "subtract" (func $subtract (param i32 i32) (result i32)))
  (import "Math" "multiply" (func $multiply (param i32 i32) (result i32)))
  (import "Math" "divide" (func $divide (param i32 i32) (result i32)))

  (func (export "add") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    call $add
  )

  (func (export "subtract") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    call $subtract
  )

  (func (export "multiply") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    call $multiply
  )

  (func (export "divide") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    call $divide
  )

  (func (export "add_using_return") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    call $add
    i32.const 1000
    i32.add
  )
)
