(module
 (table 0 anyfunc)
 (memory $0 1)
 (export "memory" (memory $0))
 (export "_Z4facti" (func $_Z4facti))
 (func $_Z4facti (; 0 ;) (param $0 i32) (result f64)
  (local $1 i64)
  (local $2 i64)
  (block $label$0
   (br_if $label$0
    (i32.lt_s
     (get_local $0)
     (i32.const 1)
    )
   )
   (set_local $1
    (i64.add
     (i64.extend_s/i32
      (get_local $0)
     )
     (i64.const 1)
    )
   )
   (set_local $2
    (i64.const 1)
   )
   (loop $label$1
    (set_local $2
     (i64.mul
      (get_local $2)
      (tee_local $1
       (i64.add
        (get_local $1)
        (i64.const -1)
       )
      )
     )
    )
    (br_if $label$1
     (i64.gt_s
      (get_local $1)
      (i64.const 1)
     )
    )
   )
   (return
    (f64.convert_s/i64
     (get_local $2)
    )
   )
  )
  (f64.const 1)
 )
)
