(module
 (table 0 anyfunc)
 (memory $0 1)
 (export "memory" (memory $0))
 (export "_Z12testFunctionPi" (func $_Z12testFunctionPi))
 (func $_Z12testFunctionPi (; 0 ;) (param $0 i32) (result i32)
  (i32.add
   (get_local $0)
   (i32.const 28)
  )
 )
)
