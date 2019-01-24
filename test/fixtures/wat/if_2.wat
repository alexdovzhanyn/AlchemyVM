(module
  (type (;0;) (func (param i32) (result i32)))
  (func (;0;) (type 0) (param i32) (result i32)
    i32.const 0
    set_local 0
    i32.const 1
    if  ;; label = @1
      get_local 0
      i32.const 1
      i32.add
      set_local 0
    end
    i32.const 0
    if  ;; label = @1
      get_local 0
      i32.const 1
      i32.add
      set_local 0
    end
    get_local 0)
  (export "ifOne" (func 0)))
