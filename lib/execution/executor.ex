defmodule WaspVM.Executor do
  alias WaspVM.Stack
  alias WaspVM.Frame
  alias WaspVM.Memory
  use Bitwise
  require Logger
  require IEx
  alias Decimal, as: D

  @moduledoc false

  # Reference for tests being used: https://github.com/WebAssembly/wabt/tree/master/test

  def create_frame_and_execute(vm, addr) do
    {{inputs, _outputs}, module_ref, instr, locals} = Enum.at(vm.store.funcs, addr)

    {args, stack} = Stack.pop_multiple(vm.stack, tuple_size(inputs))

    if tuple_size(inputs) != length(args) do
      {{:error, :param_mismatch, tuple_size(inputs), length(args)}, vm}
    else
      module = Enum.find(vm.modules, & &1.ref == module_ref)

      vm = Map.put(vm, :stack, stack)

      frame = %Frame{
        module: module,
        instructions: instr,
        locals: args ++ Enum.flat_map(locals, fn l -> List.duplicate(0, l.count) end),
        next_instr: 0
      }

      execute(frame, vm)
    end
  end

  def execute(frame, vm) do
    if frame.next_instr >= length(Map.keys(frame.instructions)) do
      vm
    else
      next = frame.next_instr
      %{^next => instr} = frame.instructions
      {frame, vm} = instruction(instr, {frame, vm})

      frame = Map.put(frame, :next_instr, frame.next_instr + 1)

      execute(frame, vm)
    end
  end

  def instruction(opcode, ctx) when is_atom(opcode), do: exec_inst(ctx, opcode)
  def instruction(opcode, ctx) when is_tuple(opcode), do: exec_inst(ctx, opcode)


  ### Begin PArametric Instructions

  defp exec_inst({frame, vm}, :drop) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, stack)}
  end

  defp exec_inst({frame, vm}, :select) do
    {[c, b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if c !== 0, do: b, else: a

    {frame, Map.put(vm, :stack, Stack.push(vm.stack, val))}
  end

  defp exec_inst({frame, vm}, {:loop, _result_type}) do
    labels = [{:loop, frame.next_instr} | frame.labels]

    {Map.put(frame, :labels, labels), vm}
  end

  defp exec_inst({frame, vm}, {:br, label_idx}), do: break_to(frame, vm, label_idx)

  defp exec_inst({frame, vm}, {:br_if, label_idx}) do
    {val, stack} = Stack.pop(vm.stack)
    vm = Map.put(vm, :stack, stack)

    if val == 1, do: break_to(frame, vm, label_idx), else: {frame, vm}
  end

  defp exec_inst({frame, vm}, {:if, _type, else_idx, end_idx}) do
    {val, stack} = Stack.pop(vm.stack)
    vm = Map.put(vm, :stack, stack)

    if val != 1 do
      next_instr = if else_idx != :none, do: else_idx, else: end_idx
      {Map.put(frame, :next_instr, next_instr), vm}
    else
      {frame, vm}
    end
  end

  defp exec_inst({frame, vm}, {:else, end_idx}) do
    {Map.put(frame, :next_instr, end_idx), vm}
  end

  defp exec_inst({%{labels: []} = frame, vm}, :end), do: {frame, vm}

  defp exec_inst({frame, vm}, :end) do
    [corresponding_label | labels] = frame.labels

    case corresponding_label do
      {:loop, _instr} -> {Map.put(frame, :labels, labels), vm}
      _ -> {frame, vm}
    end
  end

  defp exec_inst({frame, vm}, :return) do
    {Map.put(frame, :next_instr, length(Map.keys(frame.instructions))), vm}
  end

  defp exec_inst({frame, vm}, :unreachable), do: {frame, vm}
  defp exec_inst({frame, vm}, :nop), do: {frame, vm}

  defp exec_inst({frame, vm}, {:call, funcidx}) do
    func_addr = Enum.at(frame.module.funcaddrs, funcidx)

    vm = create_frame_and_execute(vm, func_addr)

    {frame, vm}
  end

  ### END PARAMETRIC INSTRUCTIONS


  defp exec_inst({frame, vm}, {:i32_const, i32}) do
    {frame, Map.put(vm, :stack, Stack.push(vm.stack, i32))}
  end

  defp exec_inst({frame, vm}, {:i64_const, i64}) do
    {frame, Map.put(vm, :stack, Stack.push(vm.stack, i64))}
  end

  defp exec_inst({frame, vm}, {:f32_const, f32}) do
    {frame, Map.put(vm, :stack, Stack.push(vm.stack, f32))}
  end

  defp exec_inst({frame, vm}, {:f64_const, f64}) do
    {frame, Map.put(vm, :stack, Stack.push(vm.stack, f64))}
  end

  defp exec_inst({frame, vm}, {:i32_store, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::32>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:i64_store, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::64>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:f32_store, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::32>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:f64_store, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::64>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:i32_load, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i32::32>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 4)

    {frame, Map.put(vm, :stack, Stack.push(stack, i32))}
  end

  defp exec_inst({frame, vm}, {:i64_load, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i64::64>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 8)

    {frame, Map.put(vm, :stack, Stack.push(stack, i64))}
  end

  defp exec_inst({frame, vm}, {:f32_load, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<f32::32-float>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 4)

    {frame, Map.put(vm, :stack, Stack.push(stack, f32))}
  end

  defp exec_inst({frame, vm}, {:f64_load, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<f64::64-float>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 8)

    {frame, Map.put(vm, :stack, Stack.push(stack, f64))}
  end

  defp exec_inst({frame, vm}, {:get_local, idx}) do
    local = Enum.at(frame.locals, idx)

    {frame, Map.put(vm, :stack, Stack.push(vm.stack, local))}
  end

  # Needs revisit
  defp exec_inst({frame, vm}, {:get_global, idx}) do
    global = Enum.at(vm.globals, idx)

    {frame, Map.put(vm, :stack, Stack.push(vm.stack, global))}
  end

  # Needs revisit
  defp exec_inst({frame, vm}, {:set_global, idx}) do
    {value, stack} = Stack.pop(vm.stack)

    globals = List.replace_at(vm.globals, idx, value)

    {frame, Map.merge(vm, %{globals: globals, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:set_local, idx}) do
    {value, stack} = Stack.pop(vm.stack)

    locals = List.replace_at(frame.locals, idx, value)

    {Map.put(frame, :locals, locals), Map.put(vm, :stack, stack)}
  end

  defp exec_inst({frame, vm}, {:tee_local, idx}) do
    value = Stack.read(vm.stack)

    locals = List.replace_at(frame.locals, idx, value)

    {Map.put(frame, :locals, locals), vm}
  end


  ### Begin Simple Integer Numerics
  defp exec_inst({frame, vm}, :i32_add) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, a + b))}
  end

  defp exec_inst({frame, vm}, :i32_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    IO.inspect b
    {frame, Map.put(vm, :stack, Stack.push(stack, a - b))}
  end

  defp exec_inst({frame, vm}, :i32_mul) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, a * b))}
  end

  defp exec_inst({frame, vm}, :i32_div_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    j1 = sign_value(a, 32)
    j2 = sign_value(b, 32)

    if j2 == 0 do
      {:error, :undefined}
    else
      if j1/j2 == :math.pow(2, 31) do
        {:error, :undefined}
      else
        res = trunc(j1/j2)
        ans = sign_value(res, 32)

        {frame, Map.put(vm, :stack, Stack.push(stack, ans))}
      end
    end
  end

  defp exec_inst({frame, vm}, :i64_div_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    j1 = sign_value(a, 64)
    j2 = sign_value(b, 64)


    if j2 == 0 do
      {:error, :undefined}
    else
      if j1/j2 == :math.pow(2, 63) do
        {:error, :undefined}
      else
        res = trunc(j1/j2)
        ans = sign_value(res, 64)

        {frame, Map.put(vm, :stack, Stack.push(stack, ans))}
      end
    end
  end

  defp exec_inst({frame, vm}, :i32_div_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    if b == 0 do
      {:error, :undefined}
    else
      rem = a - (b*trunc(a/b))
      result = Integer.floor_div((a - rem), b)
      {frame, Map.put(vm, :stack, Stack.push(stack, result))}
    end
  end

  defp exec_inst({frame, vm}, :i32_rem_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    if b == 0 do
      {:error, :undefined}
    else
      j1 = sign_value(a, 32)
      j2 = sign_value(b, 32)

      rem = j1 - (j2*trunc(j1/j2))
      n = :math.pow(2, 32)
      res = n - rem

      {frame, Map.put(vm, :stack, Stack.push(stack, rem))}
    end
  end

  defp exec_inst({frame, vm}, :i64_rem_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    if b == 0 do
      {:error, :undefined}
    else
      j1 = sign_value(a, 64)
      j2 = sign_value(b, 64)

      rem = j1 - (j2*trunc(j1/j2))
      n = :math.pow(2, 64)
      res = n - rem

      {frame, Map.put(vm, :stack, Stack.push(stack, res))}
    end
  end

  defp exec_inst({frame, vm}, :i64_div_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    if b == 0 do
      {:error, :undefined}
    else
      rem = a - (b*trunc(a/b))
      result = Integer.floor_div((a - rem), b)
      {frame, Map.put(vm, :stack, Stack.push(stack, result))}
    end
  end

  defp exec_inst({frame, vm}, :i32_popcnt) do
    {a, stack} = Stack.pop(vm.stack)
    result = popcnt(a, 32)
    {frame, Map.put(vm, :stack, Stack.push(stack, result))}
  end

  defp exec_inst({frame, vm}, :i64_popcnt) do
    {a, stack} = Stack.pop(vm.stack)
    result = popcnt(a, 64)
    {frame, Map.put(vm, :stack, Stack.push(stack, result))}
  end

  defp exec_inst({frame, vm}, :i32_rem_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    if b == 0 do
      {:error, :undefined}
    else
      {frame, Map.put(vm, :stack, Stack.push(stack, a - (b*trunc(a/b))))}
    end
  end

  defp exec_inst({frame, vm}, :i64_rem_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    if b == 0 do
      {:error, :undefined}
    else
      {frame, Map.put(vm, :stack, Stack.push(stack, a - (b*trunc(a/b))))}
    end
  end

  defp exec_inst({frame, vm}, :i64_add) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    {frame, Map.put(vm, :stack, Stack.push(stack, a + b))}
  end

  defp exec_inst({frame, vm}, :i64_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    {frame, Map.put(vm, :stack, Stack.push(stack, a - b))}
  end

  defp exec_inst({frame, vm}, :i64_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, a * b))}
  end

  ### END INTEGER NUMERICS


 ###  Begin Float Numerics

  defp exec_inst({frame, vm}, :f32_add) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a + b)))}
  end

  defp exec_inst({frame, vm}, :f32_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(b - a)))}
  end

  defp exec_inst({frame, vm}, :f32_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * b)))}
  end

  defp exec_inst({frame, vm}, :f64_add) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a + b)))}
  end

  defp exec_inst({frame, vm}, :f64_sub) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(b - a)))}
  end

  defp exec_inst({frame, vm}, :f64_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * b)))}
  end

  defp exec_inst({frame, vm}, :f32_min) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(Enum.min([a, b]))))}
  end

  defp exec_inst({frame, vm}, :f32_max) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(Enum.max([a, b]))))}
  end

  defp exec_inst({frame, vm}, :f64_min) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(Enum.min([a, b]))))}
  end

  defp exec_inst({frame, vm}, :f64_max) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(Enum.max([a, b]))))}
  end

  defp exec_inst({frame, vm}, :f32_nearest) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Kernel.round(a)))}
  end

  defp exec_inst({frame, vm}, :f64_nearest) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Kernel.round(a)))}
  end

  defp exec_inst({frame, vm}, :f32_trunc) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Kernel.trunc(a)))}
  end

  defp exec_inst({frame, vm}, :f64_trunc) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Kernel.trunc(a)))}
  end

  defp exec_inst({frame, vm}, :f32_floor) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Float.floor(a)))}
  end

  defp exec_inst({frame, vm}, :f64_floor) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Float.floor(a)))}
  end

  defp exec_inst({frame, vm}, :f32_neg) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a*-1)))}
  end

  defp exec_inst({frame, vm}, :f64_neg) do
    {a, stack} = Stack.pop(vm.stack)


    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a*-1)))}
  end

  defp exec_inst({frame, vm}, :f32_ceil) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Float.ceil(a)))}
  end

  defp exec_inst({frame, vm}, :f64_ceil) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, Float.ceil(a)))}
  end

  defp exec_inst({frame, vm}, :f32_copysign) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(copysign(a, b))))}
  end

  defp exec_inst({frame, vm}, :f64_copysign) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(copysign(a, b))))}
  end


  defp exec_inst({frame, vm}, :f32_abs) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(abs(a))))}
  end

  defp exec_inst({frame, vm}, :f64_abs) do
    {[a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(abs(a))))}
  end

  defp exec_inst({frame, vm}, :f32_sqrt) do
    {[a], stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, :math.sqrt(a)))}
  end

  defp exec_inst({frame, vm}, :f64_sqrt) do
    {[a], stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, :math.sqrt(a)))}
  end

  defp exec_inst({frame, vm}, :f32_div) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, WaspVM.Executor.float_point_op(a / b)))}
  end

  ### END FLOAT NUMERICS

  ### Being Integer STructure
  defp exec_inst({frame, vm}, :i32_rotl) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, rotl(b, a)))}
  end

  defp exec_inst({frame, vm}, :i32_rotr) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, rotr(b, a)))}
  end

  defp exec_inst({frame, vm}, :i32_and) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, band(a, b)))}
  end

  defp exec_inst({frame, vm}, :i32_or) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bor(a, b)))}
  end

  defp exec_inst({frame, vm}, :i32_xor) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bxor(a, b)))}
  end



  defp exec_inst({frame, vm}, :i32_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_eqz) do
    {a, stack} = Stack.pop(vm.stack)

    val = if a === 0, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end



  defp exec_inst({frame, vm}, :i64_and) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, band(a, b)))}
  end

  defp exec_inst({frame, vm}, :i64_or) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bor(a, b)))}
  end

  defp exec_inst({frame, vm}, :i64_xor) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bxor(a, b)))}
  end



  defp exec_inst({frame, vm}, :i32_shl) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bsl(a, b)))}
  end

  defp exec_inst({frame, vm}, :i64_shl) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bsl(a, b)))}
  end



  defp exec_inst({frame, vm}, :i32_shr_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

      j2 = Integer.mod(32, b)

    {frame, Map.put(vm, :stack, Stack.push(stack, bsr(a, j2)))}
  end

  defp exec_inst({frame, vm}, :i64_shr_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    j2 = Integer.mod(b, 64)

    {frame, Map.put(vm, :stack, Stack.push(stack, bsr(a, b)))}
  end

  defp exec_inst({frame, vm}, :i32_shr_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    j2 = Integer.mod(b, 32)

    {frame, Map.put(vm, :stack, Stack.push(stack, bsr(a, j2)))}
  end

  defp exec_inst({frame, vm}, :i64_shr_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)
    j2 = Integer.mod(b, 64)

    {frame, Map.put(vm, :stack, Stack.push(stack, bsr(a, j2)))}
  end

  defp exec_inst({frame, vm}, :i64_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end



  defp exec_inst({frame, vm}, :i64_le_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a <= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end



  defp exec_inst({frame, vm}, :i64_ge_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a >= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_eqz) do
    {a, stack} = Stack.pop(vm.stack)

    val = if a === 0, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  ### Complex Integer Operations Tests Done
  defp exec_inst({frame, vm}, :i32_le_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if sign_value(a, 32) <= sign_value(b, 32), do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_ge_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if sign_value(a, 32) >= sign_value(b, 32), do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_lt_u) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a < b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_lt_u) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a < b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_lt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if sign_value(a, 32) < sign_value(b, 32), do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_lt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

      val = if sign_value(a, 64) < sign_value(b, 64), do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_gt_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a > b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_gt_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

      val = if a > b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_gt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if sign_value(a, 32) > sign_value(b, 32), do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_gt_s) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if sign_value(a, 64) > sign_value(b, 64), do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_le_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a <= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_le_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a <= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_ge_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a >= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i64_ge_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    val = if a >= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_clz) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, count_bits(:l, a)))}
  end

  defp exec_inst({frame, vm}, :i64_clz) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, count_bits(:l, a)))}
  end

  defp exec_inst({frame, vm}, :i32_ctz) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, count_bits(:t, a)))}
  end

  defp exec_inst({frame, vm}, :i64_ctz) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, count_bits(:t, a)))}
  end

  ### END Integer Structure

  defp exec_inst({frame, vm}, :f32_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f64_eq) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a === b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :i32_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f32_lt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a < b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f64_lt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a < b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f32_le) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f64_le) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f32_ge) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f64_ge) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a <= b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f32_gt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a > b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f64_gt) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b && a > b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, :f32_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, {:loop, _result_type}) do
    labels = [{frame.next_instr, frame.next_instr} | frame.labels]
    snapshots = [vm.stack | frame.snapshots]

    {Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm}
  end

  defp exec_inst({frame, vm}, {:block, _result_type, end_idx}) do
    labels = [{frame.next_instr, end_idx - 1} | frame.labels]
    snapshots = [vm.stack | frame.snapshots]

    {Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm}
  end

  defp exec_inst({frame, vm}, :f64_ne) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack)

    val = if a !== b, do: 1, else: 0

    {frame, Map.put(vm, :stack, Stack.push(stack, val))}
  end

  defp exec_inst({frame, vm}, {:if, _type, else_idx, end_idx}) do
    {val, stack} = Stack.pop(vm.stack)
    vm = Map.put(vm, :stack, stack)
    labels = [{frame.next_instr, end_idx} | frame.labels]
    snapshots = [vm.stack | frame.snapshots]

    frame = Map.merge(frame, %{labels: labels, snapshots: snapshots})
  end


  ### Memory Operations
  defp exec_inst({frame, vm}, :current_memory) do
    size = length(vm.memory.pages)

    {frame, Map.put(vm, :stack, Stack.push(vm.stack, size))}
  end

  defp exec_inst({frame, vm}, :grow_memory) do
    {pages, stack} = Stack.pop(vm.stack)

    {frame, Map.merge(vm, %{memory: Memory.grow(vm.memory, pages), stack: Stack.push(stack, length(vm.memory))})}
  end

  ### End Memory Operations

  defp exec_inst({frame, vm}, :end) do
    [_ | labels] = frame.labels
    [_ | snapshots] = frame.snapshots

    {Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm}
  end

  defp exec_inst({frame, vm}, op) do
    IO.inspect op
    IEx.pry
  end

  defp break_to(frame, vm, label_idx) do
    {label_instr_idx, next_instr} = Enum.at(frame.labels, label_idx)
    snapshot = Enum.at(frame.snapshots, label_idx)
    %{^label_instr_idx => instr} = frame.instructions

    drop_changes =
      fn type ->
        if type != :no_res do
          {res, _} = Stack.pop(vm.stack)
          Stack.push(snapshot, res)
        else
          snapshot
        end
      end

    stack =
      case instr do
        {:loop, _} -> snapshot
        {:if, res_type, _, _} -> drop_changes.(res_type)
        {:block, res_type, _} -> drop_changes.(res_type)
      end

    {Map.put(frame, :next_instr, next_instr), Map.put(vm, :stack, stack)}
  end

  # Reference https://lemire.me/blog/2017/05/29/unsigned-vs-signed-integer-arithmetic/

  defp sign_value(integer, n), do: sign_value(integer, n, :math.pow(2, 31), :math.pow(2, 32))
  defp sign_value(integer, n, lower, upper) when integer >= 0 and integer < lower, do: integer
  defp sign_value(integer, n, lower, upper) when integer < 0 and integer > -lower, do: integer
  defp sign_value(integer, n, lower, upper) when integer > lower and integer < upper, do: :math.pow(2, 32) + integer
  defp sign_value(integer, n, lower, upper) when integer > -lower and integer < -upper, do: :math.pow(2, 32) + integer


  defp popcnt(integer, 32) do
    <<integer::32>>
    |> Binary.to_list()
    |> Enum.reject(& &1 == 0)
    |> Enum.count()
  end

  defp popcnt(integer, 64) do
    <<integer::64>>
    |> Binary.to_list()
    |> Enum.reject(& &1 == 0)
    |> Enum.count()
  end

  defp rotl(number, shift), do: (number <<< shift) ||| (number >>> (0x1F &&& (32 + ~~~(shift + 1)))) &&& ~~~(0xFFFFFFFF <<< shift)
  defp rotr(number, shift), do: (number >>> shift) ||| (number <<< (0x1F &&& (32 + ~~~(-shift + 1)))) &&& ~~~(0xFFFFFFFF <<< -shift)
  def float_point_op(number) do
    D.set_context(%D.Context{D.get_context | precision: 6})

    res =
      number
      |> :erlang.float_to_binary([decimals: 6])
      |> D.new()
  end

  defp copysign(a, b) do
    a_truth =
      to_string(a)
      |> String.codepoints
      |> Enum.any?(&(&1 == "-"))

    b_truth =
      to_string(b)
      |> String.codepoints
      |> Enum.any?(&(&1 == "-"))

    if a_truth == true && b_truth == true || a_truth == false && b_truth == false  do
      a
    else
      if a_truth == true && b_truth == false || a_truth == false && b_truth == true do
        b*-1 |> IO.inspect
      end
    end
  end


  defp check_value([0, b, c, d]) when b and c and d !== 0, do: 1
  defp check_value([0, 0, c, d]) when c and d != 0, do: 2
  defp check_value([0, 0, 0, d]) when d !== 0, do: 3
  defp check_value([0, 0, 0, 0]), do: 4
  defp check_value([a, b, c, d]), do: 0

  defp count_bits(:l, number) do
    <<number::32>>
    |> Binary.to_list
    |> check_value
  end


  defp count_bits(:t, number) do
    <<number::32>>
    |> Binary.to_list
    |> Enum.reverse
    |> check_value
  end


end
