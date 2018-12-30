;;; TOOL: run-interp
(module
  (func (export "loop") (result i32)
    (local i32 i32)
    ;; loop statements now require an explicit branch to the top
    loop $cont
      get_local 1
      get_local 0
      i32.add
      set_local 1
      get_local 0
      i32.const 1
      i32.add
      set_local 0
      get_local 0
      i32.const 100000
      i32.ne

      br_if $cont
    end

    get_local 1
  )
  (func (export "loop2") (result i32)
    (local i32)

    loop $cont
      get_local 0
      i32.const 1
      i32.add
      tee_local 0
      i32.const 100000
      i32.ne

      br_if $cont
    end

    get_local 0
  )
)
(;; STDOUT ;;;
loop() => i32:10
;;; STDOUT ;;)
