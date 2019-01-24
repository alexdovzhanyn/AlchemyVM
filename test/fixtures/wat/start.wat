;; Super basic module just adds the byte <<15>> to the modules memory as a
;; start function (immediately after initialization)
(module
  (memory 1)
  (start $start)
  (func $start
    i32.const 0
    i32.const 5
    i32.const 10
    call $add
    i32.store8
  )
  (func $add (param i32 i32) (result i32)
    get_local 0
    get_local 1
    i32.add
  )
)
