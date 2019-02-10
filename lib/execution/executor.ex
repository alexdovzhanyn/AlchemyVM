defmodule WaspVM.Executor do
  alias WaspVM.Frame
  alias WaspVM.Memory
  alias WaspVM.Gas
  alias WaspVM.HostFunction.API
  use Bitwise
  use WaspVM.DSL
  require IEx
  alias Decimal, as: D

  @moduledoc false

  # Reference for tests being used: https://github.com/WebAssembly/wabt/tree/master/test

  def create_frame_and_execute(vm, addr, gas_limit, opts, gas \\ 0, stack \\ []) do
    case elem(vm.store.funcs, addr) do
      {{inputs, _outputs}, module_ref, instr, locals} ->
        {args, stack} = Enum.split(stack, tuple_size(inputs))

        %{^module_ref => module} = vm.modules

        frame = %Frame{
          module: module,
          instructions: instr,
          locals: List.to_tuple(args ++ locals),
          gas_limit: gas_limit
        }

        total_instr = map_size(instr)

        execute(frame, vm, gas, stack, total_instr, gas_limit, opts)
      {:hostfunc, {inputs, _outputs}, mname, fname, module_ref} ->
        # TODO: How should we handle gas for host functions? Does gas price get passed in?
        # Do we default to a gas value?

        {args, stack} = Enum.split(stack, tuple_size(inputs))

        %{^module_ref => module} = vm.modules

        func =
          module.resolved_imports
          |> Map.get(mname)
          |> Map.get(fname)

        # Start an API agent that isolates VM state until the host function
        # finishes running.
        {:ok, ctx} = API.start_link(vm)

        return_val = apply(func, [ctx, args])

        # Get updated state from the API agent
        vm = API.state(ctx)

        # Kill the API agent now that it's served it's purpose
        API.stop(ctx)

        # TODO: Gas needs to be updated based on the comment above instead of
        # just getting passed through
        if !is_binary(return_val) do
          {vm, gas, stack}
        else
          {vm, gas, [return_val | stack]}
        end
    end
  end

  # What happens is we pass in the main limit for the gas & the gas_limit,
  # then every iteration before we procedd we check the gas limit and the
  # returned op_gas (gas accumulted from executing that opcode)
  # Example List Options [trace: false]
  def execute(frame, vm, gas, stack, total_instr, gas_limit, opts, next_instr \\ 0)
  def execute(_frame, vm, gas, stack, _total, gas_limit, opts, _next) when gas_limit != :infinity and gas > gas_limit, do: IEx.pry #{:error, :reached_gas_limit}
  def execute(_frame, vm, gas, stack, total_instr, _gas_limit, _opts, next_instr) when next_instr >= total_instr or next_instr < 0, do: {vm, gas, stack}
  def execute(frame, vm, gas, stack, total_instr, gas_limit, opts, next_instr) do
    %{^next_instr => instr} = frame.instructions

    {{frame, vm, next_instr}, gas, stack} = instruction({frame, vm, next_instr}, gas, stack, opts, instr)

    if opts[:trace] do
      write_to_file(instr, gas)
    end

    execute(frame, vm, gas, stack, total_instr, gas_limit, opts, next_instr + 1)
  end

  defp instruction(ctx, gas, [0, b, _ | stack], _opts, :select), do: {ctx, gas + Gas.cost(:select), [b | stack]}
  defp instruction(ctx, gas, [1, _ | stack], _opts, :select), do: {ctx, gas + Gas.cost(:select), stack}
  defp instruction(ctx, gas, [1 | stack], _opts, {:br_if, label_idx}), do: break_to(ctx, gas + Gas.cost(:br_if), stack, label_idx)
  defp instruction(ctx, gas, [_ | stack], _opts, {:br_if, _label_idx}), do: {ctx, gas + Gas.cost(:br_if), stack}
  defp instruction({_frame, vm, _n} = ctx, gas, stack, _opts, :current_memory),  do: {ctx, gas + Gas.cost(:current_memory), [length(vm.memory.pages) | stack]}
  defp instruction({frame, _vm, _n} = ctx, gas, stack, _opts, {:get_local, idx}), do: {ctx, gas + Gas.cost(:get_local), [elem(frame.locals, idx) | stack]}
  defp instruction({_frame, vm, _n} = ctx, gas, stack, _opts, {:get_global, idx}), do: {ctx, gas + Gas.cost(:get_global), [Enum.at(vm.globals, idx) | stack]}
  defp instruction(ctx, gas, [_ | stack], _opts, :drop), do: {ctx, gas + Gas.cost(:drop), stack}
  defp instruction(ctx, gas, stack, _opts, {:br, label_idx}), do: break_to(ctx, gas + Gas.cost(:br), stack, label_idx)
  defp instruction({%{labels: []} = frame, vm, n}, gas, stack, _opts, :end), do: {{frame, vm, n}, gas + Gas.cost(:end, true), stack}
  defp instruction({frame, vm, _n}, gas, stack, _opts, {:else, end_idx}), do: {{frame, vm, end_idx}, gas + Gas.cost(:else), stack}
  defp instruction({frame, vm, _n}, gas, stack, _opts, :return), do: {{frame, vm, -10}, gas + Gas.cost(:return), stack}
  defp instruction(ctx, gas, stack, _opts, :unreachable), do: {ctx, gas + Gas.cost(:unreachable), stack}
  defp instruction(ctx, gas, stack, _opts, :nop), do: {ctx, gas + Gas.cost(:nop), stack}



  # Begin i32 Instructions =====================================================

  definstr i32_const(immediates: [i32]) do
    {ctx, gas + Gas.cost(:i32_const), [<<i32::integer-32-little>> | stack]}
  end

  definstr i32_add(<<a::integer-32-little>>, <<b::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_add), [<<(a + b)::integer-32-little>> | stack]}
  end

  definstr i32_sub(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_sub), [<<(a - b)::integer-32-little>> | stack]}
  end

  definstr i32_mul(<<a::integer-32-little>>, <<b::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_mul), [<<(a * b)::integer-32-little>> | stack]}
  end

  definstr i32_div_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    if b == 0 do
      trap("Divide by zero in i32.div_s")
    else
      if a / b >= 2147483648 do
        trap("Out of bounds in i32.div_s")
      end

      res = <<trunc(a / b)::integer-32-little-signed>>

      {ctx, gas + Gas.cost(:i32_div_s), [res | stack]}
    end
  end

  definstr i32_div_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    if b == 0 do
      trap("Divide by zero in i32.div_s")
    end

    res = <<trunc(a / b)::integer-32-little>>

    {ctx, gas + Gas.cost(:i32_div_u), [res | stack]}
  end

  definstr i32_rem_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    if b == 0 do
      trap("Divide by zero in i32.rem_s")
    end

    {ctx, gas + Gas.cost(:i32_rem_s), [<<rem(a, b)::integer-32-little-signed>> | stack]}
  end

  defp instruction(_ctx, _gas, [<<0, 0, 0, 0>> | _], _opts, :i32_rem_u) do
    trap("Divide by zero in i32.rem_u")
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_rem_u) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    {ctx, gas + Gas.cost(:i32_rem_u), [<<rem(a, b)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_rotl) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    result = rotl(b, a)

    {ctx, gas + Gas.cost(:i32_rotl), [<<result::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_rotr) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    result = rotr(b, a)

    {ctx, gas + Gas.cost(:i32_rotr), [<<result::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_and) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    {ctx, gas + Gas.cost(:i32_and), [<<(a &&& b)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_or) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    {ctx, gas + Gas.cost(:i32_or), [<<(a ||| b)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_xor) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    {ctx, gas + Gas.cost(:i32_xor), [<<bxor(a, b)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_shl) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    {ctx, gas + Gas.cost(:i32_shl), [<<(a <<< b)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_shr_u) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    {ctx, gas + Gas.cost(:i32_shr_u), [<<(a >>> b)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_shr_s) do
    <<a::integer-32-little-signed>> = i32a
    <<b::integer-32-little-signed>> = i32b

    {ctx, gas + Gas.cost(:i32_shr_s), [<<(a >>> b)::integer-32-little-signed>> | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :i32_eq) when a === b do
    {ctx, gas + Gas.cost(:i32_eq), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_, _ | stack], _opts, :i32_eq) do
    {ctx, gas + Gas.cost(:i32_eq), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :i32_ne) when a !== b do
    {ctx, gas + Gas.cost(:i32_ne), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :i32_ne) do
    {ctx, gas + Gas.cost(:i32_ne), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [<<0, 0, 0, 0>> | stack], _opts, :i32_eqz) do
    {ctx, gas + Gas.cost(:i32_eqz), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_ | stack], _opts, :i32_eqz) do
    {ctx, gas + Gas.cost(:i32_eqz), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_lt_u) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_lt_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_gt_u) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_gt_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_le_u) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_le_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_ge_u) do
    <<a::integer-32-little>> = i32a
    <<b::integer-32-little>> = i32b

    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_ge_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_le_s) do
    <<a::integer-32-little-signed>> = i32a
    <<b::integer-32-little-signed>> = i32b

    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_le_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_ge_s) do
    <<a::integer-32-little-signed>> = i32a
    <<b::integer-32-little-signed>> = i32b

    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_ge_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_lt_s) do
    <<a::integer-32-little-signed>> = i32a
    <<b::integer-32-little-signed>> = i32b

    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_lt_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i32b, i32a | stack], _opts, :i32_gt_s) do
    <<a::integer-32-little-signed>> = i32a
    <<b::integer-32-little-signed>> = i32b

    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_gt_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i32 | stack], _opts, :i32_popcnt) do
    count =
      (for <<bit::1 <- i32 >>, do: bit)
      |> Enum.reject(& &1 !== 1)
      |> length()

    {ctx, gas + Gas.cost(:i32_popcnt, count), [<<count::integer-32-little>> | stack]}
  end

  # TODO: Revisit
  defp instruction(ctx, gas, [i32 | stack], _opts, :i32_ctz) do
    num_zeros =
      (for <<bit::1 <- i32 >>, do: bit)
      |> trailing_zeros()

    {ctx, gas + Gas.cost(:i32_ctz, num_zeros), [<<num_zeros::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32 | stack], _opts, :i32_clz) do
    num_zeros =
      (for <<bit::1 <- i32 >>, do: bit)
      |> leading_zeros()

    {ctx, gas + Gas.cost(:i32_clz, num_zeros), [<<num_zeros::integer-32-little>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i32_load, _alignment, offset}) do
    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    {ctx, gas + Gas.cost(:i32_load), [i32 | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i32_load8_s, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i8bin =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    <<i8::integer-8-little-signed>> = i8bin

    sign = if i8 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i32_load8_s), [i8bin <> <<sign, sign, sign>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i32_load16_s, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i16bin =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    <<i16::integer-16-little-signed>> = i16bin

    sign = if i16 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i32_load16_s), [i16bin <> <<sign, sign>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i32_load8_u, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i8 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    {ctx, gas + Gas.cost(:i32_load8_u), [i8 <> <<0, 0, 0>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i32_load16_u, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i16 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    {ctx, gas + Gas.cost(:i32_load16_u), [i16 <> <<0, 0>> | stack]}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:i32_store, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i32_store), stack}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:i32_store8, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    # Value is little endian, so grabbing the first byte is effectively wrapping
    <<i8::bytes-size(1), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i8)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i32_store8), stack}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:i32_store16, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    # Value is little endian, so grabbing the first 2 bytes is effectively wrapping
    <<i16::bytes-size(2), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i16)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i32_store16), stack}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :i32_trunc_u_f32) do
    <<f32::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:i32_trunc_u_f32), [<<trunc(f32)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :i32_trunc_s_f32) do
    <<f32::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:i32_trunc_s_f32), [<<trunc(f32)::integer-32-little-signed>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :i32_trunc_u_f64) do
    <<f64::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:i32_trunc_u_f32), [<<trunc(f64)::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :i32_trunc_s_f64) do
    <<f64::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:i32_trunc_s_f64), [<<trunc(f64)::integer-32-little-signed>> | stack]}
  end

  defp instruction(ctx, gas, [a | stack], _opts, :i32_reinterpret_f32) do
    {ctx, gas + Gas.cost(:i32_reinterpret_f32), [a | stack]}
  end

  defp instruction(ctx, gas, [i64 | stack], _opts, :i32_wrap_i64) do
    <<i32::bytes-size(4), _rest::binary>> = i64

    {ctx, gas + Gas.cost(:i32_wrap_i64), [i32 | stack]}
  end

  # End i32 Instructions =======================================================
  # Begin i64 Instructions =====================================================

  defp instruction(ctx, gas, stack, _opts, {:i64_const, i64}) do
    {ctx, gas + Gas.cost(:i64_const), [<<i64::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_add) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_add), [<<(a + b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_sub) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_sub), [<<(a - b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_mul) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_mul), [<<(a * b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_div_s) do
    <<a::integer-64-little-signed>> = i64a
    <<b::integer-64-little-signed>> = i64b

    if b == 0 do
      trap("Divide by zero in i64.div_s")
    else
      if a / b == 9.223372036854776e18 do
        trap("Out of bounds in i64.div_s")
      else
        {ctx, gas + Gas.cost(:i64_div_s), [<<trunc(a / b)::integer-64-little-signed>> | stack]}
      end
    end
  end

  defp instruction(_ctx, _gas, [<<0, 0, 0, 0, 0, 0, 0, 0>> | _], _opts, :i64_div_u) do
    trap("Divide by zero in i64.div_u")
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_div_u) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_div_u), [<<trunc(a / b)::integer-64-little>> | stack]}
  end

  defp instruction(_ctx, _gas, [<<0, 0, 0, 0, 0, 0, 0, 0>> | _], _opts, :i64_rem_s) do
    trap("Divide by zero in i64.rem_s")
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_rem_s) do
    <<a::integer-64-little-signed>> = i64a
    <<b::integer-64-little-signed>> = i64b

    {ctx, gas + Gas.cost(:i64_rem_s), [<<rem(a, b)::integer-64-little-signed>> | stack]}
  end

  defp instruction(_ctx, _gas, [<<0, 0, 0, 0, 0, 0, 0, 0>> | _], _opts, :i64_rem_u) do
    trap("Divide by zero in i64.rem_u")
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_rem_u) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_rem_u), [<<rem(a, b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_rotl) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = rotl(b, a)

    {ctx, gas + Gas.cost(:i64_rotl), [<<result::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_rotr) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = rotr(b, a)

    {ctx, gas + Gas.cost(:i64_rotr), [<<result::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_and) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_and), [<<(a &&& b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_or) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_or), [<<(a ||| b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_xor) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_xor), [<<bxor(a, b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_shl) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_shl), [<<(a <<< b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_shr_u) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    {ctx, gas + Gas.cost(:i64_shr_u), [<<(a >>> b)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_shr_s) do
    <<a::integer-64-little-signed>> = i64a
    <<b::integer-64-little-signed>> = i64b

    {ctx, gas + Gas.cost(:i64_shr_s), [<<(a >>> b)::integer-64-little-signed>> | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :i64_eq) when a === b do
    {ctx, gas + Gas.cost(:i64_eq), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_, _ | stack], _opts, :i64_eq) do
    {ctx, gas + Gas.cost(:i64_eq), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :i64_ne) when a !== b do
    {ctx, gas + Gas.cost(:i64_ne), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_, _ | stack], _opts, :i64_ne) do
    {ctx, gas + Gas.cost(:i64_ne), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [<<0, 0, 0, 0, 0, 0, 0, 0>> | stack], _opts, :i64_eqz) do
    {ctx, gas + Gas.cost(:i64_eqz), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_ | stack], _opts, :i64_eqz) do
    {ctx, gas + Gas.cost(:i64_eqz), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_lt_u) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_lt_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_gt_u) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_gt_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_le_u) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_le_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_ge_u) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_ge_u), [result | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_le_s) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_le_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_ge_s) do
    <<a::integer-64-little>> = i64a
    <<b::integer-64-little>> = i64b

    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_ge_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_lt_s) do
    <<a::integer-64-little-signed>> = i64a
    <<b::integer-64-little-signed>> = i64b

    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_lt_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i64b, i64a | stack], _opts, :i64_gt_s) do
    <<a::integer-64-little-signed>> = i64a
    <<b::integer-64-little-signed>> = i64b

    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_gt_s), [result | stack]}
  end

  defp instruction(ctx, gas, [i64 | stack], _opts, :i64_popcnt) do
    count =
      (for <<bit::1 <- i64 >>, do: bit)
      |> Enum.reject(& &1 !== 1)
      |> length()

    {ctx, gas + Gas.cost(:i64_popcnt, count), [<<count::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64 | stack], _opts, :i64_clz) do
    num_zeros =
      (for <<bit::1 <- i64 >>, do: bit)
      |> leading_zeros()

    {ctx, gas + Gas.cost(:i64_clz, num_zeros), [<<num_zeros::integer-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64 | stack], _opts, :i64_ctz) do
    num_zeros =
      (for <<bit::1 <- i64 >>, do: bit)
      |> trailing_zeros()

    {ctx, gas + Gas.cost(:i64_ctz, num_zeros), [<<num_zeros::integer-32-little>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i64_load, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i64 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 8)

    {ctx, gas + Gas.cost(:i64_load), [i64 | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i64_load8_s, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i8 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    sign = if i8 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_load8_s), [i8 <> <<sign, sign, sign, sign, sign, sign, sign>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i64_load16_s, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i16 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    sign = if i16 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_load16_s), [i16 <> <<sign, sign, sign, sign, sign, sign>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i64_load32_s, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    sign = if i32 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_load32_s), [i32 <> <<sign, sign, sign, sign>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i64_load8_u, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i8 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    {ctx, gas + Gas.cost(:i64_load8_u), [i8 <> <<0, 0, 0, 0, 0, 0, 0>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i64_load16_u, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i16 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    {ctx, gas + Gas.cost(:i64_load16_u), [i16 <> <<0, 0, 0, 0, 0, 0>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:i64_load32_u, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    i32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    {ctx, gas + Gas.cost(:i64_load32_u), [i32 <> <<0, 0, 0, 0>> | stack]}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:i64_store, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store), stack}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:i64_store8, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    <<i8::bytes-size(1), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i8)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store8), stack}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:i64_store16, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    <<i16::bytes-size(2), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i16)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store16), stack}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:i64_store32, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    <<i32::bytes-size(4), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i32)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store32), stack}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :i64_trunc_u_f32) do
    <<f32::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:i64_trunc_u_f32), [<<trunc(f32)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :i64_trunc_s_f32) do
    <<f32::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:i64_trunc_s_f32), [<<trunc(f32)::integer-64-little-signed>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :i64_trunc_u_f64) do
    <<f64::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:i64_trunc_u_f64), [<<trunc(f64)::integer-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :i64_trunc_s_f64) do
    <<f64::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:i64_trunc_s_f64), [<<trunc(f64)::integer-64-little-signed>> | stack]}
  end

  defp instruction(ctx, gas, [i32 | stack], _opts, :i64_extend_u_i32) do
    {ctx, gas + Gas.cost(:i64_extend_u_i32), [i32 <> <<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [i32a | stack], _opts, :i64_extend_s_i32) do
    <<i32::integer-32-little-signed>> = i32a

    sign = if i32 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_extend_s_i32), [i32a <> <<sign, sign, sign, sign>> | stack]}
  end

  defp instruction(ctx, gas, [a | stack], _opts, :i64_reinterpret_f64) do
    {ctx, gas + Gas.cost(:i64_reinterpret_f32), [a | stack]}
  end

  # End i64 Instructions =======================================================
  # Begin f32 Instructions =====================================================

  defp instruction(ctx, gas, stack, _opts, {:f32_const, f32}) do
    {ctx, gas + Gas.cost(:f32_const), [<<f32::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_lt) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_lt), [result | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_le) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_le), [result | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_ge) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_ge), [result | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_gt) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_gt), [result | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_add) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    {ctx, gas + Gas.cost(:f32_add), [<<(a + b)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_sub) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    {ctx, gas + Gas.cost(:f32_sub), [<<(a - b)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_mul) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    {ctx, gas + Gas.cost(:f32_mul), [<<(a * b)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [<<0, 0, 0, 0>>, _ | stack], _opts, :f32_div) do
    trap("Divide by zero in f32.div")
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_div) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    {ctx, gas + Gas.cost(:f32_div), [<<(a / b)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f32_sqrt) do
    <<a::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:f32_sqrt), [<<:math.sqrt(a)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f32_nearest) do
    <<a::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:f32_nearest), [<<round(a)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f32_trunc) do
    <<a::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:f32_trunc), [<<trunc(a)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f32_floor) do
    <<a::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:f32_floor), [<<Float.floor(a)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f32_ceil) do
    <<a::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:f32_ceil), [<<Float.ceil(a)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f32_neg) do
    <<a::float-32-little>> = f32a

    result = a * -1

    result = if result == 0.0, do: 0.0, else: result

    {ctx, gas + Gas.cost(:f32_neg), [<<result::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f32_abs) do
    <<a::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:f32_abs), [<<abs(a)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_min) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    {ctx, gas + Gas.cost(:f32_min), [<<min(a, b)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_max) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    {ctx, gas + Gas.cost(:f32_max), [<<max(a, b)::float-32-little>> | stack]}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:f32_load, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    f32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    {ctx, gas + Gas.cost(:f32_load), [f32 | stack]}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:f32_store, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:f32_store), stack}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :f32_eq) when a === b do
    {ctx, gas + Gas.cost(:f32_eq), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_, _ | stack], _opts, :f32_eq) do
    {ctx, gas + Gas.cost(:f32_eq), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :f32_ne) when a !== b do
    {ctx, gas + Gas.cost(:f32_ne), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_, _ | stack], _opts, :f32_ne) do
    {ctx, gas + Gas.cost(:f32_ne), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [f32b, f32a | stack], _opts, :f32_copysign) do
    <<a::float-32-little>> = f32a
    <<b::float-32-little>> = f32b

    magnitude = abs(a)
    sign = if b >= 0, do: 1, else: -1

    result = magnitude * sign

    # This needs to be here because of a weird bug (?) where 0.0 * -1 would be
    # <<0, 0, 0, 128>> instead of <<0, 0, 0, 0>>, even though both were 0.0
    result = if result == 0.0, do: 0.0, else: result

    {ctx, gas + Gas.cost(:f32_copysign), [<<result::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32a | stack], _opts, :f32_convert_s_i32) do
    <<a::integer-32-little-signed>> = i32a

    {ctx, gas + Gas.cost(:f32_convert_s_i32), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32a | stack], _opts, :f32_convert_u_i32) do
    <<a::integer-32-little>> = i32a

    {ctx, gas + Gas.cost(:f32_convert_u_i32), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64a | stack], _opts, :f32_convert_s_i64) do
    <<a::integer-64-little-signed>> = i64a

    {ctx, gas + Gas.cost(:f32_convert_s_i64), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64a | stack], _opts, :f32_convert_u_i64) do
    <<a::integer-64-little>> = i64a

    {ctx, gas + Gas.cost(:f32_convert_u_i64), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  # TODO: Revisit this -- it's likely incorrect
  defp instruction(ctx, gas, [f64 | stack], _opts, :f32_demote_f64) do
    {ctx, gas + Gas.cost(:f32_demote_f64), [float_demote(f64 * 1.0000000) | stack]}
  end

  defp instruction(ctx, gas, [a | stack], _opts, :f32_reinterpret_i32) do
    {ctx, gas + Gas.cost(:f32_reinterpret_i32), [a | stack]}
  end

  # End f32 Instructions =======================================================
  # Begin f64 Instructions =====================================================

  defp instruction(ctx, gas, stack, _opts, {:f64_const, f64}) do
    {ctx, gas + Gas.cost(:f64_const), [<<f64::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_add) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    {ctx, gas + Gas.cost(:f64_add), [<<(a + b)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_sub) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    {ctx, gas + Gas.cost(:f64_sub), [<<(a - b)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_mul) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    {ctx, gas + Gas.cost(:f64_mul), [<<(a * b)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_min) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    {ctx, gas + Gas.cost(:f64_min), [<<min(a, b)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_max) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    {ctx, gas + Gas.cost(:f64_max), [<<max(a, b)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_lt) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_lt), [result | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_le) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_le), [result | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_ge) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_ge), [result | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_gt) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_gt), [result | stack]}
  end

  defp instruction({frame, vm, n}, gas, [value, address | stack], _opts, {:f64_store, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:f64_store), stack}
  end

  defp instruction({frame, vm, _n} = ctx, gas, [address | stack], _opts, {:f64_load, _alignment, offset}) do
    mem_addr = hd(frame.module.memaddrs)

    # Address can only be an i32 in the MVP
    <<i32addr::integer-32-little>> = address

    f64 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 8)

    {ctx, gas + Gas.cost(:f64_load), [f64 | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :f64_eq) when a === b do
    {ctx, gas + Gas.cost(:f64_eq), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_, _ | stack], _opts, :f64_eq) do
    {ctx, gas + Gas.cost(:f64_eq), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [b, a | stack], _opts, :f64_ne) when a !== b do
    {ctx, gas + Gas.cost(:f64_ne), [<<1, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [_, _ | stack], _opts, :f64_ne) do
    {ctx, gas + Gas.cost(:f64_ne), [<<0, 0, 0, 0>> | stack]}
  end

  defp instruction(ctx, gas, [f64b, f64a | stack], _opts, :f64_copysign) do
    <<a::float-64-little>> = f64a
    <<b::float-64-little>> = f64b

    magnitude = abs(a)
    sign = if b >= 0, do: 1, else: -1

    result = magnitude * sign

    result = if result == 0.0, do: 0.0, else: result

    {ctx, gas + Gas.cost(:f64_copysign), [<<result::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :f64_nearest) do
    <<a::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:f64_nearest), [<<round(a)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :f64_trunc) do
    <<a::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:f64_trunc), [<<trunc(a)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :f64_floor) do
    <<a::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:f64_floor), [<<Float.floor(a)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :f64_neg) do
    <<a::float-64-little>> = f64a

    result = a * -1

    result = if result == 0.0, do: 0.0, else: result

    {ctx, gas + Gas.cost(:f64_neg), [<<result::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :f64_abs) do
    <<a::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:f64_abs), [<<abs(a)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :f64_sqrt) do
    <<a::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:f64_sqrt), [<<:math.sqrt(a)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f64a | stack], _opts, :f64_ceil) do
    <<a::float-64-little>> = f64a

    {ctx, gas + Gas.cost(:f64_ceil), [<<Float.ceil(a)::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64a | stack], _opts, :f64_convert_s_i64) do
    <<i64::integer-64-little-signed>> = i64a

    {ctx, gas + Gas.cost(:f32_convert_s_i64), [<<i64::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i64a | stack], _opts, :f64_convert_u_i64) do
    <<i64::integer-64-little>> = i64a

    {ctx, gas + Gas.cost(:f32_convert_u_i64), [<<i64::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32a | stack], _opts, :f64_convert_s_i32) do
    <<i32::integer-32-little-signed>> = i32a

    {ctx, gas + Gas.cost(:f32_convert_s_i32), [<<i32::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [i32a | stack], _opts, :f64_convert_u_i32) do
    <<i32::integer-32-little>> = i32a

    {ctx, gas + Gas.cost(:f64_convert_u_i32), [<<i32::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [f32a | stack], _opts, :f64_promote_f32) do
    <<f32::float-32-little>> = f32a

    {ctx, gas + Gas.cost(:f64_promote_f32), [<<f32::float-64-little>> | stack]}
  end

  defp instruction(ctx, gas, [a | stack], _opts, :f64_reinterpret_i64) do
    {ctx, gas + Gas.cost(:f64_reinterpret_i64), [a | stack]}
  end

  # End f64 Instructions =======================================================
  # Begin Type Agnostic Instructions ===========================================

  defp instruction({frame, vm, n}, gas, [<<1, 0, 0, 0>> | stack], _opts, {:if, _type, _else_idx, end_idx}) do
    labels = [{n, end_idx} | frame.labels]
    snapshots = [stack | frame.snapshots]

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, gas + Gas.cost(:if), stack}
  end

  defp instruction({frame, vm, _n}, gas, [_val | stack], _opts, {:if, _type, else_idx, end_idx}) do
    next_instr = if else_idx != :none, do: else_idx, else: end_idx
    {{frame, vm, next_instr}, gas + Gas.cost(:if), stack}
  end

  defp instruction({frame, vm, n}, gas, stack, _opts, :end) do
    [_ | labels] = frame.labels
    [_ | snapshots] = frame.snapshots

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, gas + Gas.cost(:end, false), stack}
  end

  defp instruction({frame, vm, n}, gas, stack, opts, {:call, funcidx}) do
    %{^funcidx => func_addr} = frame.module.funcaddrs

    # TODO: Maybe this shouldn't pass the existing stack in?
    {vm, gas, stack} = create_frame_and_execute(vm, func_addr, frame.gas_limit, opts, gas, stack)

    {{frame, vm, n}, gas + Gas.cost(:call), stack}
  end

  defp instruction({frame, vm, n}, gas, [value | stack], _opts, {:set_global, idx}) do
    globals = List.replace_at(vm.globals, idx, value)

    {{frame, Map.put(vm, :globals, globals), n}, gas + Gas.cost(:set_global), stack}
  end

  defp instruction({frame, vm, n}, gas, [value | stack], _opts, {:set_local, idx}) do
    locals = put_elem(frame.locals, idx, value)

    {{Map.put(frame, :locals, locals), vm, n}, gas + Gas.cost(:set_local), stack}
  end

  defp instruction({frame, vm, n}, gas, [value | _] = stack, _opts, {:tee_local, idx}) do
    locals = put_elem(frame.locals, idx, value)

    {{Map.put(frame, :locals, locals), vm, n}, gas + Gas.cost(:tee_local), stack}
  end

  defp instruction({frame, vm, n}, gas, [i32pages | stack], _opts, :grow_memory) do
    <<pages::integer-32-little>> = i32pages

    {{frame, Map.put(vm, :memory, Memory.grow(vm.memory, pages)), n}, gas + Gas.cost(:grow_memory), [length(vm.memory) | stack]}
  end

  defp instruction({frame, vm, n}, gas, stack, _opts, {:loop, _result_type}) do
    labels = [{n, n} | frame.labels]
    snapshots = [stack | frame.snapshots]

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, gas + Gas.cost(:loop), stack}
  end

  defp instruction({frame, vm, n}, gas, stack, _opts, {:block, _result_type, end_idx}) do
    labels = [{n, end_idx - 1} | frame.labels]
    snapshots = [stack | frame.snapshots]

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, gas + Gas.cost(:block), stack}
  end

  defp instruction(ctx, gas, stack, opts, op) do
    IO.inspect op
    IEx.pry
  end

  defp break_to({frame, vm, _n}, gas, stack, label_idx) do
    {label_instr_idx, next_instr} = Enum.at(frame.labels, label_idx)
    snapshot = Enum.at(frame.snapshots, label_idx)

    %{^label_instr_idx => instr} = frame.instructions

    drop_changes =
      fn type ->
        if type != :no_res do
          [res | _] = stack
          [res | snapshot]
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

    {{frame, vm, next_instr}, gas + 2, stack}
  end

  # Reference https://lemire.me/blog/2017/05/29/unsigned-vs-signed-integer-arithmetic/
  # TODO: Wrong
  defp reint(:f32, :i32, float), do: reint(float)
  defp reint(:f32, :i64, float), do: reint(float)
  defp reint(:f64, :i64, float), do: reint(float)
  defp reint(float) do
    float
    |> :erlang.float_to_binary()
    |> :binary.decode_unsigned()
  end

  defp sign_value(integer, n), do: sign_value(integer, n, :math.pow(2, 31), :math.pow(2, 32))
  defp sign_value(integer, _n, lower, _upper) when integer >= 0 and integer < lower, do: integer
  defp sign_value(integer, _n, lower, _upper) when integer < 0 and integer > -lower, do: integer
  defp sign_value(integer, _n, lower, upper) when integer > lower and integer < upper, do: :math.pow(2, 32) + integer
  defp sign_value(integer, _n, lower, upper) when integer > -lower and integer < -upper, do: :math.pow(2, 32) + integer

  # TODO: This is implemented wrong. Should count number of bits set to 1,
  # currently counts number of bytes set to 1
  defp popcnt(integer, 32), do: popcnt(<<integer::32>>)
  defp popcnt(integer, 64), do: popcnt(<<integer::64>>)
  defp popcnt(binary) do
    binary
    |> Binary.to_list()
    |> Enum.reject(& &1 == 0)
    |> Enum.count()
  end

  defp rotl(number, shift), do: (number <<< shift) ||| (number >>> (0x1F &&& (32 + ~~~(shift + 1)))) &&& ~~~(0xFFFFFFFF <<< shift)
  defp rotr(number, shift), do: (number >>> shift) ||| (number <<< (0x1F &&& (32 + ~~~(-shift + 1)))) &&& ~~~(0xFFFFFFFF <<< -shift)

  def float_point_op(number) do
    D.set_context(%D.Context{D.get_context | precision: 6})

    number
    |> :erlang.float_to_binary([decimals: 6])
    |> D.new()
  end

  def float_demote(number) do
    D.set_context(%D.Context{D.get_context | precision: 6})

    number * 10
    |> :erlang.float_to_binary([decimals: 6])
    |> D.new()
  end

  def float_promote(number) do
    D.set_context(%D.Context{D.get_context | precision: 6})

    number
    |> :erlang.float_to_binary([decimals: 6])
    |> D.new()
  end


  # Return a value whose absolute value matches that of a, but whose sign bit
  # matches that of b. For example, copysign(42.0, -1.0) and copysign(-42.0, -1.0)
  # both return -42.0.
  # TODO: This is implemented incorrectly, need to revisit
  defp copysign(a, b) do
    a_truth =
      to_string(a)
      |> String.codepoints
      |> Enum.any?(&(&1 == "-"))

    b_truth =
      to_string(b)
      |> String.codepoints
      |> Enum.any?(&(&1 == "-"))

    # TODO: What if neither match?
    if a_truth && b_truth || !a_truth && !b_truth  do
      a
    else
      if a_truth && !b_truth || !a_truth && b_truth do
        b * -1
      end
    end
  end

  defp trap(reason), do: raise "Runtime Error -- #{reason}"

  defp check_value([0, 0, 0, 0]), do: 4
  defp check_value([0, 0, 0, _]), do: 3
  defp check_value([0, 0, _, _]), do: 2
  defp check_value([0, _, _, _]), do: 1
  defp check_value(_), do: 0

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

  defp wrap_to_value(:i8, integer), do: integer &&& 0xFF
  defp wrap_to_value(:i16, integer), do: integer &&& 0xFFFF
  defp wrap_to_value(:i32, integer), do: integer &&& 0xFFFFFFFF

  defp bin_wrap(:i64, :i32, integer) do
    <<integer::64>>
    |> Binary.to_list()
    |> Enum.reverse
    |> Binary.from_list
    |> :binary.decode_unsigned()
    |> Bitwise.band(0xFFFFFFFF)
  end

  defp bin_wrap(:i8, integer), do: :binary.decode_unsigned(<<integer::8>>)
  defp bin_wrap(:i16, integer), do: :binary.decode_unsigned(<<integer::16>>)
  defp bin_wrap(:i32, integer), do: :binary.decode_unsigned(<<integer::32>>)

  defp bin_wrap_signed(:i32, :i8, integer), do: bin_wrap(:i8, integer) &&& 0xFFFFFFFF
  defp bin_wrap_signed(:i32, :i16, integer), do: bin_wrap(:i16, integer) &&& 0xFFFFFFFF
  defp bin_wrap_signed(:i64, :i8, integer), do: bin_wrap(:i8, integer) &&& 0xFFFFFFFFFFFFFFFF
  defp bin_wrap_signed(:i64, :i16, integer), do: bin_wrap(:i16, integer) &&& 0xFFFFFFFFFFFFFFFF
  defp bin_wrap_signed(:i64, :i32, integer), do: bin_wrap(:i32, integer) &&& 0xFFFFFFFFFFFFFFFF

  defp bin_wrap_unsigned(:i32, :i8, integer), do: bin_wrap(:i8, integer) &&& 0xFF
  defp bin_wrap_unsigned(:i32, :i16, integer), do: bin_wrap(:i16, integer) &&& 0xFFFF
  defp bin_wrap_unsigned(:i64, :i8, integer), do: bin_wrap(:i8, integer) &&& 0xFFFF
  defp bin_wrap_unsigned(:i64, :i16, integer), do: bin_wrap(:i16, integer) &&& 0xFFFF
  defp bin_wrap_unsigned(:i64, :i32, integer), do: bin_wrap(:i32, integer) &&& 0xFFFFFFFF

  defp bin_trunc(:f32, :i32, float), do: round(float)
  defp bin_trunc(:f32, :i64, float), do: round(float)
  defp bin_trunc(:f64, :i64, float), do: round(float)

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
    zero_leading_map = Enum.map(1..target, fn _ -> 1 end)

    Integer.undigits(zero_leading_map ++ bin, 2)
  end

  defp trailing_zeros(bin_list) do
    bin_list
    |> Enum.reverse()
    |> Enum.find_index(& &1 == 1)
  end

  defp leading_zeros(bin_list), do: Enum.find_index(bin_list, & &1 == 1)

  defp create_entry(instruction) when not is_tuple(instruction), do: to_string(instruction)
  defp create_entry({instruction, _variable}), do: create_entry(instruction)
  defp create_entry({:if, _rtype, _else_idx, _end_idx}), do: create_entry(:if)
  defp create_entry(other), do: create_entry("Trace not implemented for: #{inspect(other)}")

  defp write_to_file(instruction, gas) do
    './trace.log'
    |> Path.expand()
    |> Path.absname()
    |> File.write("#{create_entry(instruction)} #{gas}\n", [:append])
  end
end
