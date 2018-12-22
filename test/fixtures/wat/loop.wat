;;; TOOL: run-interp
(module
  (func (export "loop") (result i32)
    (local i32 i32)
    ;; loop statements now require an explicit branch to the top
    loop $cont
      loop $spam
        get_local 1
        get_local 0
        i32.add
        set_local 1
        get_local 0
        i32.const 1
        i32.add
        set_local 0
        get_local 0
        i32.const 5
        i32.lt_s
        br_if $spam
      end

      get_local 1
      get_local 0
      i32.add
      set_local 1
      get_local 0
      i32.const 1
      i32.add
      set_local 0
      get_local 0
      i32.const 5
      i32.lt_s

      br_if $cont
    end

    get_local 1
  )
)
(;; STDOUT ;;;
loop() => i32:10
;;; STDOUT ;;)
