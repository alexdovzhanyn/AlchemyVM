;;; TOOL: run-interp
;;; ARGS*: --enable-multi-value
(module
  ;; (func (export "block-multi-result") (result i32)
  ;;   block (result i32 i32)
  ;;     i32.const 1
  ;;     i32.const 2
  ;;   end
  ;;   i32.add
  ;; )
  ;;
  ;; (func (export "block-multi-result-br") (result i32)
  ;;   block $b (result i32 i32)
  ;;     block
  ;;       i32.const 15
  ;;       i32.const 7
  ;;       br $b
  ;;     end
  ;;     i32.const -1
  ;;     i32.const -2
  ;;   end
  ;;   drop)

  (func (export "block-param") (result i32)
    block $blk (result i32)
      i32.const 1
      i32.const 1
      i32.eq
      if
        i32.const 87
        br $blk
      end
      i32.const 2
      i32.const 5
      i32.add
    end
  )
)
(;; STDOUT ;;;
block-multi-result() => i32:3
block-multi-result-br() => i32:15
block-param() => f32:2.000000
;;; STDOUT ;;)
