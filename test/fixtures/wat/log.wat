(module
  (import "env" "consoleLog" (func $consoleLog (param f32)))
  (export "getSqrt" (func $getSqrt))
  (func $getSqrt (param f32) (result f32)
    get_local 0
    call $consoleLog

    get_local 0
    f32.sqrt
  )
)
