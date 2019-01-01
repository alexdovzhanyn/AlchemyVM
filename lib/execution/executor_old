defmodule WaspVM.Executor do
  alias WaspVM.Frame
  alias WaspVM.Memory
  use Bitwise
  require Logger
  require IEx
  alias Decimal, as: D

  @moduledoc false

  # Reference for tests being used: https://github.com/WebAssembly/wabt/tree/master/test

  def create_frame_and_execute(vm, addr, stack \\ []) do
    {{inputs, _outputs}, module_ref, instr, locals} = elem(vm.store.funcs, addr)

    # We don't need the stack that was passed in anymore at this point, it's
    # safe to discard it since we'll just use an empty new stack from here on out.
    args = Enum.take(stack, tuple_size(inputs))

    %{^module_ref => module} = vm.modules

    frame = %Frame{
      module: module,
      instructions: instr,
      locals: List.to_tuple(args ++ locals)
    }

    total_instr = map_size(instr)

    execute(frame, vm, [], total_instr)
  end

  def execute(_frame, vm, stack, total_instr, next_instr) when next_instr >= total_instr or next_instr < 0, do: {vm, stack}
  def execute(frame, vm, stack, total_instr, next_instr \\ 0) do
    %{^next_instr => instr} = frame.instructions

    {{frame, vm, next_instr}, stack} = instruction(instr, frame, vm, stack, next_instr)

    execute(frame, vm, stack, total_instr, next_instr + 1)
  end

  def instruction(opcode, f, v, s, n) when is_atom(opcode), do: exec_inst({f, v, n}, s, opcode)
  def instruction(opcode, f, v, s, n) when is_tuple(opcode), do: exec_inst({f, v, n}, s, opcode)

  defp exec_inst(ctx, [_ | stack], :drop), do: {ctx, stack}
  defp exec_inst(ctx, stack, {:br, label_idx}), do: break_to(ctx, stack, label_idx)
  defp exec_inst(ctx, [val | stack], {:br_if, label_idx}) when val != 1, do: {ctx, stack}
  defp exec_inst(ctx, [_ | stack], {:br_if, label_idx}), do: break_to(ctx, stack, label_idx)
  defp exec_inst(ctx, stack, {:i32_const, i32}), do: {ctx, [i32 | stack]}
  defp exec_inst(ctx, stack, {:i64_const, i64}), do: {ctx, [i64 | stack]}
  defp exec_inst(ctx, stack, {:f32_const, f32}), do: {ctx, [f32 | stack]}
  defp exec_inst(ctx, stack, {:f64_const, f64}), do: {ctx, [f64 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_add), do: {ctx, [a + b | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_sub), do: {ctx, [a - b | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_mul), do: {ctx, [a * b | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_add), do: {ctx, [a + b | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_sub), do: {ctx, [a - b | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_mul), do: {ctx, [a * b | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_le_s) when a <= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_ge_s) when a >= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_lt_u) when a < b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_lt_u) when a < b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_gt_u) when a > b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_gt_u) when a > b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_le_u) when a <= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_le_u) when a <= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_ge_u) when a >= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_ge_u) when a >= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_eq) when a === b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_eq) when a === b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i64_ne) when a !== b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f32_eq) when a === b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f64_eq) when a === b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_ne) when a !== b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f32_lt) when a < b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f64_lt) when a < b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f32_le) when a <= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f64_le) when a <= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f32_ge) when a <= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f64_ge) when a <= b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f32_gt) when a > b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f64_gt) when a > b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f32_ne) when a !== b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :f64_ne) when a !== b, do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [b, a | stack], :i32_eq), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_eq), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_ne), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_le_s), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_ge_s), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i32_lt_u), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_lt_u), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i32_gt_u), do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_gt_u), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i32_le_u), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_le_u), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i32_ge_u), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i64_ge_u), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f32_eq), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f64_eq), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :i32_ne), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f32_lt), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f64_lt), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f32_le) , do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f64_le), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f32_ge), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f64_ge), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f32_gt), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f64_gt), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f32_ne), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [_, _ | stack], :f64_ne), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [0 | stack], :i32_eqz), do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [_ | stack], :i32_eqz), do: {ctx, [0 | stack]}
  defp exec_inst(ctx, [0 | stack], :i64_eqz), do: {ctx, [1 | stack]}
  defp exec_inst(ctx, [_ | stack], :i64_eqz), do: {ctx, [0 | stack]}
  defp exec_inst({%{labels: []} = frame, vm, n}, stack, :end), do: {{frame, vm, n}, stack}
  defp exec_inst({frame, vm, n}, stack, {:else, end_idx}), do: {{frame, vm, end_idx}, stack}
  defp exec_inst({frame, vm, n}, stack, :return), do: {{frame, vm, -10}, stack}
  defp exec_inst(ctx, stack, :unreachable), do: {ctx, stack}
  defp exec_inst(ctx, stack, :nop), do: {ctx, stack}

  defp exec_inst(ctx, [c, b, a | stack], :select) do
    val = if c === 1, do: a, else: b

    {ctx, [val | stack]}
  end

  defp exec_inst(ctx, [val | stack], {:if, _, _, _}) when val == 1, do: {ctx, stack}
  defp exec_inst({frame, vm, n}, [val | stack], {:if, _type, else_idx, end_idx}) do
    next_instr = if else_idx != :none, do: else_idx, else: end_idx
    {{frame, vm, next_instr}, stack}
  end

  defp exec_inst({frame, vm, n}, stack, :end) do
    [corresponding_label | labels] = frame.labels

    case corresponding_label do
      {:loop, _instr} -> {{Map.put(frame, :labels, labels), vm, n}, stack}
      _ -> {{frame, vm, n}, stack}
    end
  end

  defp exec_inst({frame, vm, n}, stack, {:call, funcidx}) do
    %{^funcidx => func_addr} = frame.module.funcaddrs

    # TODO: Maybe this shouldn't pass the existing stack in?
    {vm, stack} = create_frame_and_execute(vm, func_addr, stack)

    {{frame, vm, n}, stack}
  end

  ### END PARAMETRIC INSTRUCTIONS

  defp exec_inst({frame, vm, n}, [value, address | stack], {:i32_store, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::32>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, stack}
  end

  defp exec_inst({frame, vm, n}, [value, address | stack], {:i64_store, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::64>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, stack}
  end

  defp exec_inst({frame, vm, n}, [value, address | stack], {:f32_store, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::32>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, stack}
  end

  defp exec_inst({frame, vm, n}, [value, address | stack], {:f64_store, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<value::64>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, stack}
  end

  defp exec_inst({frame, vm, n} = ctx, [address | stack], {:i32_load, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i32::32>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 4)

    {ctx, [i32 | stack]}
  end

  defp exec_inst({frame, vm, n} = ctx, [address | stack], {:i64_load, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i64::64>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 8)

    {ctx, [i64 | stack]}
  end

  defp exec_inst({frame, vm, n} = ctx, [address | stack], {:f32_load, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<f32::32-float>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 4)

    {ctx, [f32 | stack]}
  end

  defp exec_inst({frame, vm, n} = ctx, [address | stack], {:f64_load, _alignment, offset}) do
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<f64::64-float>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 8)

    {ctx, [f64 | stack]}
  end

  defp exec_inst({frame, vm, n} = ctx, stack, {:get_local, idx}) do
    {ctx, [elem(frame.locals, idx) | stack]}
  end

  # Needs revisit
  defp exec_inst({frame, vm, n} = ctx, stack, {:get_global, idx}) do
    global = Enum.at(vm.globals, idx)

    {ctx, [global | stack]}
  end

  # Needs revisit
  defp exec_inst({frame, vm, n}, [value | stack], {:set_global, idx}) do
    globals = List.replace_at(vm.globals, idx, value)

    {{frame, Map.put(vm, :globals, globals), n}, stack}
  end

  defp exec_inst({frame, vm, n}, [value | stack], {:set_local, idx}) do
    locals = put_elem(frame.locals, idx, value)

    {{Map.put(frame, :locals, locals), vm, n}, stack}
  end

  defp exec_inst({frame, vm, n}, [value | _] = stack, {:tee_local, idx}) do
    locals = put_elem(frame.locals, idx, value)

    {{Map.put(frame, :locals, locals), vm, n}, stack}
  end

  ### Begin Simple Integer Numerics
  defp exec_inst(ctx, [b, a | stack], :i32_div_s) do
    j1 = sign_value(a, 32)
    j2 = sign_value(b, 32)

    if j2 == 0 do
      {:error, :undefined}
    else
      if j1 / j2 == 2147483648 do
        {:error, :undefined}
      else
        res = trunc(j1 / j2)
        ans = sign_value(res, 32)

        {ctx, [ans | stack]}
      end
    end
  end

  defp exec_inst(ctx, [b, a | stack], :i64_div_s) do
    j1 = sign_value(a, 64)
    j2 = sign_value(b, 64)

    if j2 == 0 do
      {:error, :undefined}
    else
      if j1 / j2 == 9.223372036854776e18 do
        {:error, :undefined}
      else
        res = trunc(j1 / j2)
        ans = sign_value(res, 64)

        {ctx, [ans | stack]}
      end
    end
  end

  defp exec_inst(ctx, [b | _], :i32_div_u) when b == 0, do: {:error, :undefined}
  defp exec_inst(ctx, [b, a | stack], :i32_div_u) do
    rem = a - (b * trunc(a / b))
    result = Integer.floor_div((a - rem), b)
    {ctx, [result | stack]}
  end

  defp exec_inst(ctx, [b | _], :i32_rem_s) when b == 0, do: {:error, :undefined}
  defp exec_inst(ctx, [b, a | stack], :i32_rem_s) do
    j1 = sign_value(a, 32)
    j2 = sign_value(b, 32)

    rem = j1 - (j2 * trunc(j1 / j2))

    {ctx, [rem | stack]}
  end

  defp exec_inst(ctx, [b | _], :i64_rem_s) when b == 0, do: {:error, :undefined}
  defp exec_inst(ctx, [b, a | stack], :i64_rem_s) do
    j1 = sign_value(a, 64)
    j2 = sign_value(b, 64)

    rem = j1 - (j2 * trunc(j1 / j2))
    res = 1.8446744073709552e19 - rem

    {ctx, [res | stack]}
  end

  defp exec_inst(ctx, [b | _], :i64_div_u) when b == 0, do: {:error, :undefined}
  defp exec_inst(ctx, [b, a | stack], :i64_div_u) do
    rem = a - (b * trunc(a / b))
    result = Integer.floor_div((a - rem), b)
    {ctx, [result | stack]}
  end

  defp exec_inst(ctx, [a | stack], :i32_popcnt) do
    {ctx, [popcnt(a, 32) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :i64_popcnt) do
    {ctx, [popcnt(a, 64) | stack]}
  end

  defp exec_inst(ctx, [b | _], :i32_rem_u) when b == 0, do: {:error, :undefined}
  defp exec_inst(ctx, [b, a | stack], :i32_rem_u) do
    c =
      a
      |> Kernel./(b)
      |> trunc()
      |> Kernel.*(b)

    res = a - c

    {ctx, [res | stack]}
  end

  defp exec_inst(ctx, [b | _], :i64_rem_u) when b == 0, do: {:error, :undefined}
  defp exec_inst(ctx, [b, a | stack], :i64_rem_u) do
    c =
      a
      |> Kernel./(b)
      |> trunc()
      |> Kernel.*(b)

    res = a - c

    {ctx, [res | stack]}
  end

  ### END INTEGER NUMERICS


 ###  Begin Float Numerics

  defp exec_inst(ctx, [b, a | stack], :f32_add) do
    {ctx, [float_point_op(a + b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f32_sub) do
    {ctx, [float_point_op(b - a) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f32_mul) do
    {ctx, [float_point_op(a * b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f64_add) do
    {ctx, [float_point_op(a + b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f64_sub) do
    {ctx, [float_point_op(b - a) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f64_mul) do
    {ctx, [float_point_op(a * b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f32_min) do
    {ctx, [float_point_op(min(a, b)) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f32_max) do
    {ctx, [float_point_op(max(a, b)) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f64_min) do
    {ctx, [float_point_op(min(a, b)) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f64_max) do
    {ctx, [float_point_op(max(a, b)) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f32_nearest) do
    {ctx, [round(a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f64_nearest) do
    {ctx, [round(a) | stack]}
  end

<<<<<<< HEAD
  defp exec_inst({frame, vm}, :f32_trunc) do
    {a, stack} = Stack.pop(vm.stack)
    IO.inspect a
    {frame, Map.put(vm, :stack, Stack.push(stack, Kernel.trunc(a)))}
=======
  defp exec_inst(ctx, [a | stack], :f32_trunc) do
    {ctx, [trunc(a) | stack]}
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa
  end

  defp exec_inst(ctx, [a | stack], :f64_trunc) do
    {ctx, [trunc(a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f32_floor) do
    {ctx, [Float.floor(a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f64_floor) do
    {ctx, [Float.floor(a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f32_neg) do
    {ctx, [float_point_op(a * -1) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f64_neg) do
    {ctx, [float_point_op(a * -1) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f32_ceil) do
    {ctx, [Float.ceil(a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f64_ceil) do
    {ctx, [Float.ceil(a) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f32_copysign) do
    {ctx, [float_point_op(copysign(b, a)) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f64_copysign) do
    {ctx, [float_point_op(copysign(b, a)) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f32_abs) do
    {ctx, [float_point_op(abs(a)) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f64_abs) do
    {ctx, [float_point_op(abs(a)) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f32_sqrt) do
    {ctx, [float_point_op(:math.sqrt(a)) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :f64_sqrt) do
    {ctx, [float_point_op(:math.sqrt(a)) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :f32_div) do
    {ctx, [float_point_op(a / b) | stack]}
  end

  ### END FLOAT NUMERICS

  ### Being Integer STructure
  defp exec_inst(ctx, [b, a | stack], :i32_rotl) do
    {ctx, [rotl(b, a) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_rotr) do
    {ctx, [rotr(b, a) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_and) do
    {ctx, [band(a, b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_or) do
    {ctx, [bor(a, b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_xor) do
    {ctx, [bxor(a, b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i64_and) do
    {ctx, [band(a, b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i64_or) do
    {ctx, [bor(a, b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i64_xor) do
    {ctx, [bxor(a, b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_shl) do
    {ctx, [bsl(a, b) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i64_shl) do
    {ctx, [bsl(a, b) | stack]}
  end

<<<<<<< HEAD


  defp exec_inst({frame, vm}, :i32_shr_u) do
    {[b, a], stack} = Stack.pop_multiple(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, log_shr(a, b)))}
=======
  defp exec_inst(ctx, [b, a | stack], :i32_shr_u) do
    j2 = Integer.mod(b, 32)

    {ctx, [bsr(a, j2) | stack]}
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa
  end

  defp exec_inst(ctx, [b, a | stack], :i64_shr_u) do
    j2 = Integer.mod(b, 64)

    {ctx, [bsr(a, j2) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_shr_s) do
    j2 = Integer.mod(b, 32)

    {ctx, [bsr(a, j2) | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i64_shr_s) do
    j2 = Integer.mod(b, 64)

    {ctx, [bsr(a, j2) | stack]}
  end

  ### Complex Integer Operations Tests Done
  defp exec_inst(ctx, [b, a | stack], :i32_le_s) do
    val = if sign_value(a, 32) <= sign_value(b, 32), do: 1, else: 0

    {ctx, [val | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_ge_s) do
    val = if sign_value(a, 32) >= sign_value(b, 32), do: 1, else: 0

    {ctx, [val | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_lt_s) do
    val = if sign_value(a, 32) < sign_value(b, 32), do: 1, else: 0

    {ctx, [val | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i64_lt_s) do
    val = if sign_value(a, 64) < sign_value(b, 64), do: 1, else: 0

    {ctx, [val | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i32_gt_s) do
    val = if sign_value(a, 32) > sign_value(b, 32), do: 1, else: 0

    {ctx, [val | stack]}
  end

  defp exec_inst(ctx, [b, a | stack], :i64_gt_s) do
    val = if sign_value(a, 64) > sign_value(b, 64), do: 1, else: 0

    {ctx, [val | stack]}
  end

  defp exec_inst(ctx, [a | stack], :i32_clz) do
    {ctx, [count_bits(:l, a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :i64_clz) do
    {ctx, [count_bits(:l, a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :i32_ctz) do
    {ctx, [count_bits(:t, a) | stack]}
  end

  defp exec_inst(ctx, [a | stack], :i64_ctz) do
    {ctx, [count_bits(:t, a) | stack]}
  end

  ### END Integer Structure

  defp exec_inst({frame, vm, n}, stack, {:loop, _result_type}) do
    labels = [{n, n} | frame.labels]
    snapshots = [stack | frame.snapshots]

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, stack}
  end

  defp exec_inst({frame, vm, n}, stack, {:block, _result_type, end_idx}) do
    labels = [{n, end_idx - 1} | frame.labels]
    snapshots = [stack | frame.snapshots]

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, stack}
  end

  defp exec_inst({frame, vm, n}, [val | stack], {:if, _type, else_idx, end_idx}) do
    labels = [{n, end_idx} | frame.labels]
    snapshots = [stack | frame.snapshots]

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, stack}
  end

  ### Memory Operations
<<<<<<< HEAD
  defp exec_inst({frame, vm}, :memory_size) do
    size = length(vm.memory.pages)

    {frame, Map.put(vm, :stack, Stack.push(vm.stack, size))}
  end

  defp exec_inst({frame, vm}, :memory_grow) do
    {pages, stack} = Stack.pop(vm.stack)

    {frame, Map.merge(vm, %{memory: Memory.grow(vm.memory, pages), stack: Stack.push(stack, length(vm.memory))})}
=======
  defp exec_inst({frame, vm, n} = ctx, stack, :current_memory) do
    {ctx, [length(vm.memory.pages) | stack]}
  end

  defp exec_inst({frame, vm, n}, [pages | stack], :grow_memory) do
    {{frame, Map.put(vm, :memory, Memory.grow(vm.memory, pages)), n}, [length(vm.memory) | stack]}
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa
  end

  defp exec_inst({frame, vm}, {:i32_load8_s, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

<<<<<<< HEAD
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i8::8>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 1)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_signed(:i32, :i8, i8)))}
  end

  defp exec_inst({frame, vm}, {:i32_load16_s, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)
=======
  defp exec_inst({frame, vm, n}, stack, :end) do
    [_ | labels] = frame.labels
    [_ | snapshots] = frame.snapshots

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, stack}
  end

  defp exec_inst(ctx, stack, op) do
    IO.inspect op
    IEx.pry
  end

  defp break_to({frame, vm, _n}, stack, label_idx) do
    {label_instr_idx, next_instr} = Enum.at(frame.labels, label_idx)
    snapshot = Enum.at(frame.snapshots, label_idx)

    %{^next_instr => instr} = frame.instructions

    drop_changes =
      fn type ->
        if type != :no_res do
          [res | _] = vm.stack
          [res | snapshot]
        else
          snapshot
        end
      end
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa

    <<i16::16>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 2)

<<<<<<< HEAD
    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_signed(:i32, :i16, i16)))}
=======
    {{frame, vm, next_instr}, stack}
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa
  end

  defp exec_inst({frame, vm}, {:i64_load8_s, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

<<<<<<< HEAD
    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i8::8>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 1)
=======
  defp sign_value(integer, n), do: sign_value(integer, n, 2147483648, 4294967296) # 2^31...2^32
  defp sign_value(integer, n, lower, upper) when integer >= 0 and integer < lower, do: integer
  defp sign_value(integer, n, lower, upper) when integer < 0 and integer > -lower, do: integer
  defp sign_value(integer, n, lower, upper) when integer > lower and integer < upper, do: upper + integer
  defp sign_value(integer, n, lower, upper) when integer > -lower and integer < -upper, do: upper + integer
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_signed(:i64, :i8, i8)))}
  end

  defp exec_inst({frame, vm}, {:i64_load16_s, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i16::16>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 2)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_signed(:i64, :i16, i16)))}
  end

  defp exec_inst({frame, vm}, {:i64_load32_s, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

<<<<<<< HEAD
    <<i32::32>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 4)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_signed(:i64, :i32, i32)))}
  end

  defp exec_inst({frame, vm}, {:i32_load8_u, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)
=======
    if a_truth && b_truth || !a_truth && !b_truth  do
      a
    else
      if a_truth && !b_truth || !a_truth && b_truth do
        b * -1
      end
    end
  end

  defp check_value([0, 0, 0, 0]), do: 4
  defp check_value([0, 0, 0, _]), do: 3
  defp check_value([0, 0, _, _]), do: 2
  defp check_value([0, _, _, _]), do: 1
  defp check_value(_), do: 0
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa

    <<i8::8>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 1)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_unsigned(:i32, :i8, abs(i8))))}
  end

<<<<<<< HEAD
  defp exec_inst({frame, vm}, {:i32_load16_u, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i16::16>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 2)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_unsigned(:i32, :i16, abs(i16))))}
  end

  defp exec_inst({frame, vm}, {:i64_load8_u, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i8::8>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 1)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_unsigned(:i64, :i8, abs(i8))))}
  end

  defp exec_inst({frame, vm}, {:i64_load16_u, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i16::16>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 2)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_unsigned(:i64, :i16, abs(i16))))}
  end

  defp exec_inst({frame, vm}, {:i64_load32_u, _alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    # Will only work while each module can only have 1 mem
    mem_addr = hd(frame.module.memaddrs)

    <<i32::32>> =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(address + offset, 4)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap_unsigned(:i64, :i32, abs(i32))))}
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

  defp exec_inst({frame, vm}, {:i32_store8, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> IO.inspect
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, <<wrap_to_value(:i8, value)::8>>)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:i32_store16, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem_addr = hd(frame.module.memaddrs)

    value =
      <<wrap_to_value(:i16, value)::16>>
      |> Binary.to_list
      |> Enum.reverse()
      |> Binary.from_list


    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:i64_store8, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem_addr = hd(frame.module.memaddrs)

    value = <<wrap_to_value(:i8, value)::8>>
    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:i64_store16, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem_addr = hd(frame.module.memaddrs)

    value =
      <<wrap_to_value(:i16, value)::16>>
      |> Binary.to_list
      |> Enum.reverse()
      |> Binary.from_list


    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)

    store = Map.put(vm.store, :mems, store_mems)

    {frame, Map.merge(vm, %{store: store, stack: stack})}
  end

  defp exec_inst({frame, vm}, {:i64_store32, _alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack)

    mem_addr = hd(frame.module.memaddrs)

    value =
      <<wrap_to_value(:i32, value)::32>>
      |> Binary.to_list
      |> Enum.reverse()
      |> Binary.from_list


    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(address + offset, value)

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

  ### End Memory Operations

  ### Begin Wrapping & Trunc Operations

  defp exec_inst({frame, vm}, :i32_wrap_i64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_wrap(:i64, :i32, a)))}
  end

  defp exec_inst({frame, vm}, :i32_trunc_u_f32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f32, :i32, a)))}
  end

  defp exec_inst({frame, vm}, :i32_trunc_s_f32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f32, :i32, a)))}
  end

  defp exec_inst({frame, vm}, :i32_trunc_u_f64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f32, :i32, a)))}
  end

  defp exec_inst({frame, vm}, :i32_trunc_s_f64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f32, :i32, a)))}
  end

  defp exec_inst({frame, vm}, :i64_trunc_u_f32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f32, :i64, a)))}
  end

  defp exec_inst({frame, vm}, :i64_trunc_s_f32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f32, :i64, a)))}
  end

  defp exec_inst({frame, vm}, :i64_trunc_u_f64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f64, :i64, a)))}
  end

  defp exec_inst({frame, vm}, :i64_trunc_s_f64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, bin_trunc(:f64, :i64, a)))}
  end

  defp exec_inst({frame, vm}, :f32_convert_s_i32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :f32_convert_u_i32) do
    {a, stack} = Stack.pop(vm.stack)
    a = band(a, 0xFFFFFFFF)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :f32_convert_s_i64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :f32_convert_u_i64) do
    {a, stack} = Stack.pop(vm.stack)
    a = band(a, 0xFFFFFFFFFFFFFF)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :f64_convert_s_i64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :f64_convert_u_i64) do
    {a, stack} = Stack.pop(vm.stack)
    a = band(a, 0xFFFFFFFFFFFFFF)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :f64_convert_s_i32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :f64_convert_u_i32) do
    {a, stack} = Stack.pop(vm.stack)
    a = band(a, 0xFFFFFFFF)
    {frame, Map.put(vm, :stack, Stack.push(stack, float_point_op(a * 1.000000)))}
  end

  defp exec_inst({frame, vm}, :i64_extend_u_i32) do
    {a, stack} = Stack.pop(vm.stack)
    a = round(:math.pow(2, 32) + a)
    {frame, Map.put(vm, :stack, Stack.push(stack, a))}
  end

  defp exec_inst({frame, vm}, :i64_extend_s_i32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, band(a, 0xFFFFFFFFFFFFFFFF)))}
  end

  defp exec_inst({frame, vm}, :f32_demote_f64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_demote(a * 1.0000000)))}
  end

  defp exec_inst({frame, vm}, :f64_promote_f32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, float_promote(a * 1.0000000)))}
  end

  defp exec_inst({frame, vm}, :i32_reinterpret_f32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, reint(:f32, :i32, a)))}
  end

  defp exec_inst({frame, vm}, :i64_reinterpret_f32) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, reint(:f32, :i64, a)))}
  end

  defp exec_inst({frame, vm}, :f64_reinterpret_i64) do
    {a, stack} = Stack.pop(vm.stack)

    {frame, Map.put(vm, :stack, Stack.push(stack, reint(:f64, :i64, a)))}
  end


  ### End Trunc, Wrap & Convert


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
    instr = Enum.at(frame.instructions, label_instr_idx)

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

  defp reint(:f32, :i32, float) do
    integer =
      :erlang.float_to_binary(float)
     |> :binary.decode_unsigned()
  end

  defp reint(:f32, :i64, float) do
    integer =
      :erlang.float_to_binary(float)
     |> :binary.decode_unsigned()
  end

  defp reint(:f64, :i64, float) do
    integer =
      :erlang.float_to_binary(float)
     |> :binary.decode_unsigned()
  end

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

  def float_demote(number) do
    D.set_context(%D.Context{D.get_context | precision: 6})

    res =
      number * 10
      |> :erlang.float_to_binary([decimals: 6])
      |> D.new()
  end

  def float_promote(number) do
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
        b * -1
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

=======
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa
  defp count_bits(:t, number) do
    <<number::32>>
    |> Binary.to_list
    |> Enum.reverse
    |> check_value
  end
<<<<<<< HEAD

  defp wrap_to_value(:i8, integer), do: integer &&& 0xFF
  defp wrap_to_value(:i16, integer), do: integer &&& 0xFFFF
  defp wrap_to_value(:i32, integer), do: integer &&& 0xFFFFFFFF

  defp bin_wrap(:i64, :i32, integer) do
    integer =
      <<integer::64>>
      |> Binary.to_list()
      |> Enum.reverse
      |> Binary.from_list
      |> :binary.decode_unsigned()

    value = integer &&& 0xFFFFFFFF
  end

  defp bin_wrap(:i8, integer), do: :binary.decode_unsigned(<<integer::8>>)
  defp bin_wrap(:i16, integer), do: :binary.decode_unsigned(<<integer::16>>)
  defp bin_wrap(:i32, integer), do: :binary.decode_unsigned(<<integer::32>>)
  defp bin_wrap_signed(:i32, :i8, integer), do: bin_wrap(:i8, integer) && 0xFFFFFFFF
  defp bin_wrap_signed(:i32, :i16, integer), do: bin_wrap(:i16, integer) && 0xFFFFFFFF
  defp bin_wrap_signed(:i64, :i8, integer), do: bin_wrap(:i8, integer) && 0xFFFFFFFFFFFFFFFF
  defp bin_wrap_signed(:i64, :i16, integer), do: bin_wrap(:i16, integer) && 0xFFFFFFFFFFFFFFFF
  defp bin_wrap_signed(:i64, :i32, integer), do: bin_wrap(:i32, integer) && 0xFFFFFFFFFFFFFFFF
  defp bin_wrap_unsigned(:i32, :i8, integer), do: bin_wrap(:i8, integer) && 0xFF
  defp bin_wrap_unsigned(:i32, :i16, integer), do: bin_wrap(:i16, integer) && 0xFFFF
  defp bin_wrap_unsigned(:i64, :i8, integer), do: bin_wrap(:i8, integer) && 0xFFFF
  defp bin_wrap_unsigned(:i64, :i16, integer), do: bin_wrap(:i16, integer) && 0xFFFF
  defp bin_wrap_unsigned(:i64, :i32, integer), do: bin_wrap(:i32, integer) && 0xFFFFFFFF



  defp bin_trunc(:f32, :i32, float), do: round(float)
  defp bin_trunc(:f32, :i64, float), do: round(float)
  defp bin_trunc(:f64, :i64, float), do: round(float)
  defp negate(int), do: &(-&1)

  defp log_shr(integer, shift) do
    bin =
      integer
      |> Integer.to_string(2)
      |> String.codepoints
      |> Enum.reverse
      |> Enum.drop((shift))
      |> Enum.map(fn str -> String.to_integer(str) end)

      bin_size = Enum.count(bin)
      target = 32 - bin_size - shift

      zero_leading_map =
        1..target
        |> Enum.map(fn x -> 1 end)

        zero_leading_map ++ bin
        |> Integer.undigits(2)
  end

=======
>>>>>>> 5c98ac4c434e3d10cea19a9d61f8126cd29c0bfa
end
