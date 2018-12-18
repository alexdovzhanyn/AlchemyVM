defmodule WaspVM.Executor do
  alias WaspVM.Stack
  alias WaspVM.Memory
  use Bitwise
  require Logger
  require IEx

  def execute(instructions, vm) when is_list(instructions) do
    Enum.reduce(instructions, vm, & instruction(&2, &1))
  end

  def instruction(vm, opcode) when is_atom(opcode), do: exec_inst(vm, opcode)
  def instruction(vm, op) when is_tuple(op), do: exec_inst(vm, op)

  defp exec_inst(vm, {:i32_const, i32}) do
    Map.put(vm, :stack, Stack.push(vm.stack, i32))
  end

  defp exec_inst(vm, {:i64_const, i64}) do
    Map.put(vm, :stack, Stack.push(vm.stack, i64))
  end

  defp exec_inst(vm, {:f32_const, f32}) do
    Map.put(vm, :stack, Stack.push(vm.stack, f32))
  end

  defp exec_inst(vm, {:f64_const, f64}) do
    Map.put(vm, :stack, Stack.push(vm.stack, f64))
  end

  defp exec_inst(vm, {:i32_store, alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem = Memory.put_at(vm.memory, address + offset, <<value::32>>)

    Map.merge(vm, %{memory: mem, stack: stack})
  end

  defp exec_inst(vm, {:i64_store, alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem = Memory.put_at(vm.memory, address + offset, <<value::64>>)

    Map.merge(vm, %{memory: mem, stack: stack})
  end

  defp exec_inst(vm, {:f32_store, alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem = Memory.put_at(vm.memory, address + offset, <<value::32>>)

    Map.merge(vm, %{memory: mem, stack: stack})
  end

  defp exec_inst(vm, {:f64_store, alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem = Memory.put_at(vm.memory, address + offset, <<value::64>>)

    Map.merge(vm, %{memory: mem, stack: stack})
  end

  defp exec_inst(vm, {:i32_load, alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    <<i32::32>> = Memory.get_at(vm.memory, address + offset, 4)

    Map.put(vm, :stack, Stack.push(stack, i32))
  end

  defp exec_inst(vm, {:i64_load, alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    <<i64::64>> = Memory.get_at(vm.memory, address + offset, 8)

    Map.put(vm, :stack, Stack.push(stack, i64))
  end

  defp exec_inst(vm, {:f32_load, alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    <<f32::32-float>> = Memory.get_at(vm.memory, address + offset, 4)

    Map.put(vm, :stack, Stack.push(stack, f32))
  end

  defp exec_inst(vm, {:f64_load, alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    <<f64::64-float>> = Memory.get_at(vm.memory, address + offset, 8)

    Map.put(vm, :stack, Stack.push(stack, f64))
  end

  defp exec_inst(vm, {:get_local, idx}) do
    local = Enum.at(vm.locals, idx)

    Map.put(vm, :stack, Stack.push(vm.stack, local))
  end

  defp exec_inst(vm, {:get_global, idx}) do
    global = Enum.at(vm.globals, idx)

    Map.put(vm, :stack, Stack.push(vm.stack, global))
  end

  defp exec_inst(vm, {:set_global, idx}) do
    {value, stack} = Stack.pop(vm.stack)

    globals = List.replace_at(vm.globals, idx, value)

    Map.merge(vm, %{globals: globals, stack: stack})
  end

  defp exec_inst(vm, {:set_local, idx}) do
    {value, stack} = Stack.pop(vm.stack)

    locals = List.replace_at(vm.locals, idx, value)

    Map.merge(vm, %{locals: locals, stack: stack})
  end

  defp exec_inst(vm, {:tee_local, idx}) do
    value = Stack.read(vm.stack)

    locals = List.replace_at(vm.locals, idx, value)

    Map.put(vm, :locals, locals)
  end

  defp exec_inst(vm, :i32_add) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a + b))
  end

  defp exec_inst(vm, :i32_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a - b))
  end

  defp exec_inst(vm, :i32_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a * b))
  end

  defp exec_inst(vm, :f32_add) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    Map.put(vm, :stack, Stack.push(stack, a + b))
  end

  defp exec_inst(vm, :f32_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    Map.put(vm, :stack, Stack.push(stack, a - b))
  end

  defp exec_inst(vm, :f32_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a * b))
  end

  defp exec_inst(vm, :f64_add) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    Map.put(vm, :stack, Stack.push(stack, a + b))
  end

  defp exec_inst(vm, :f64_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    Map.put(vm, :stack, Stack.push(stack, a - b))
  end

  defp exec_inst(vm, :f64_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a * b))
  end

  defp exec_inst(vm, :i32_rem_s) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, rem(a, b)))
  end

  defp exec_inst(vm, :f32_min) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    min = Enum.min([a, b])
    Map.put(vm, :stack, Stack.push(stack, min))
  end

  defp exec_inst(vm, :f32_max) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    max = Enum.max([a, b])

    Map.put(vm, :stack, Stack.push(stack, max))
  end

  defp exec_inst(vm, :f64_min) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    min = Enum.min([a, b])
    Map.put(vm, :stack, Stack.push(stack, min))
  end

  defp exec_inst(vm, :f32_nearest) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Kernel.round(a)))
  end

  defp exec_inst(vm, :f64_nearest) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Kernel.round(a)))
  end

  defp exec_inst(vm, :f32_trunc) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Kernel.trunc(a)))
  end

  defp exec_inst(vm, :f64_trunc) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Kernel.trunc(a)))
  end

  defp exec_inst(vm, :f32_floor) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Float.floor(a)))
  end

  defp exec_inst(vm, :f64_floor) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Float.floor(a)))
  end

  defp exec_inst(vm, :f32_neg) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a*-1))
  end

  defp exec_inst(vm, :f32_ceil) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Float.ceil(a)))
  end

  defp exec_inst(vm, :f64_ceil) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Float.ceil(a)))
  end

  defp exec_inst(vm, :f64_neg) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a*-1))
  end

  defp exec_inst(vm, :f32_abs) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, abs(a)))
  end

  defp exec_inst(vm, :f64_abs) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, abs(a)))
  end

  defp exec_inst(vm, :f64_max) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    max = Enum.max([a, b])

    Map.put(vm, :stack, Stack.push(stack, max))
  end

  defp exec_inst(vm, :f32_sqrt) do
    {[a], stack} = Stack.pop(vm.stack)


    Map.put(vm, :stack, Stack.push(stack, :math.sqrt(a)))
  end

  defp exec_inst(vm, :f64_sqrt) do
    {[a], stack} = Stack.pop(vm.stack)


    Map.put(vm, :stack, Stack.push(stack, :math.sqrt(a)))
  end


  defp exec_inst(vm, :f32_div) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a / b))
  end

  defp exec_inst(vm, :i32_div_) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a / b))
  end

  defp exec_inst(vm, :i64_div_s) do
    # Truncated to zero
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Kernel.div(a, b)))
  end

  defp exec_inst(vm, :i64_div_u) do
    # Floored
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, floor_div(a, b)))
  end

  defp exec_inst(vm, :i64_rem_s) do
    # Truncated to zero
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, Kernel.rem(a, b)))
  end

  defp exec_inst(vm, :i64_rem_u) do
    # Floored
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, rem(a, b)))
  end

  defp exec_inst(vm, :i32_popcnt) do
    {a, stack} = Stack.pop(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, []))
  end

  defp exec_inst(vm, :i64_popcnt) do
    {a, stack} = Stack.pop(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, []))
  end

  defp exec_inst(vm, :i32_and) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a &&& b))
  end

  defp exec_inst(vm, :i32_or) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a ||| b))
  end

  defp exec_inst(vm, :i32_xor) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a ^^^ b))
  end


  defp exec_inst(vm, :i32_shr_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a >>> b))
  end

  defp exec_inst(vm, :i32_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f32_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f64_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i32_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f32_lt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a < b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f64_lt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a < b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f32_le) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f64_le) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f32_ge) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f64_ge) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f32_gt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a > b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f64_gt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a > b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f32_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :f64_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i32_lt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a < b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i32_le_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a <= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i32_gt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a > b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i32_ge_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a >= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i32_eqz) do
    {a, stack} = Stack.pop(vm.stack)

    val = if a === 0, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i64_add) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    Map.put(vm, :stack, Stack.push(stack, a + b))
  end

  defp exec_inst(vm, :i64_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    Map.put(vm, :stack, Stack.push(stack, a - b))
  end

  defp exec_inst(vm, :i64_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a * b))
  end

  defp exec_inst(vm, :i64_and) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a &&& b))
  end

  defp exec_inst(vm, :i64_or) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a ||| b))
  end

  defp exec_inst(vm, :i64_xor) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a ^^^ b))
  end

  defp exec_inst(vm, :i64_shr_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a >>> b))
  end

  defp exec_inst(vm, :i32_shl) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a <<< b))
  end

  defp exec_inst(vm, :i64_shl) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a <<< b))
  end

  defp exec_inst(vm, :i64_shr_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a >>> b))
  end

  defp exec_inst(vm, :i32_shr_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    Map.put(vm, :stack, Stack.push(stack, a >>> b))
  end

  defp exec_inst(vm, :i64_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i64_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i64_lt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a < b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i64_le_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a <= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i64_gt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a > b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i64_ge_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a >= b, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :i64_eqz) do
    {a, stack} = Stack.pop(vm.stack)

    val = if a === 0, do: 1, else: 0

    Map.put(vm, :stack, Stack.push(stack, val))
  end

  defp exec_inst(vm, :current_memory) do
    size = length(vm.memory.pages)

    Map.put(vm, :stack, Stack.push(vm.stack, size))
  end

  defp exec_inst(vm, :grow_memory) do
    {pages, stack} = Stack.pop(vm.stack)

    Map.merge(vm, %{memory: Memory.grow(vm.memory, pages), stack: Stack.push(stack, length(vm.memory))})
  end

  defp exec_inst(vm, :unreachable), do: vm

  defp exec_inst(vm, :nop), do: vm

  defp exec_inst(vm, :end), do: vm


  defp exec_inst(vm, op) do
    IEx.pry
  end








end
