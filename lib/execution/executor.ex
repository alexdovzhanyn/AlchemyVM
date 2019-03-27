defmodule AlchemyVM.Executor do
  alias AlchemyVM.Frame
  alias AlchemyVM.Memory
  alias AlchemyVM.Gas
  alias AlchemyVM.HostFunction.API
  use Bitwise
  use AlchemyVM.DSL
  require IEx
  alias Decimal, as: D

  @moduledoc false

  # Reference for tests being used: https://github.com/WebAssembly/wabt/tree/master/test

  defp typecast_param({:i32, param}), do: <<param::integer-32-little-signed>>
  defp typecast_param({:i64, param}), do: <<param::integer-64-little-signed>>
  defp typecast_param({:f32, param}), do: <<param::float-32-little>>
  defp typecast_param({:f64, param}), do: <<param::float-64-little>>

  def create_frame_and_execute(vm, addr, gas_limit, opts, gas \\ 0, stack \\ [], parameters \\ []) do
    case elem(vm.store.funcs, addr) do
      {{inputs, outputs}, module_ref, instr, locals} ->
        {args, stack} =
          if length(parameters) > 0 do
            args =
              inputs
              |> Tuple.to_list()
              |> Enum.zip(parameters)
              |> Enum.map(&typecast_param/1)

            {args, stack}
          else
            Enum.split(stack, tuple_size(inputs))
          end

        %{^module_ref => module} = vm.modules

        frame = %Frame{
          module: module,
          instructions: instr,
          locals: List.to_tuple(args ++ locals),
          gas_limit: gas_limit
        }

        total_instr = map_size(instr)

        {outputs, execute(frame, vm, gas, stack, total_instr, gas_limit, opts)}
      {:hostfunc, {inputs, outputs}, mname, fname, module_ref} ->
        {args, stack} =
          if length(parameters) > 0 do
            args =
              inputs
              |> Tuple.to_list()
              |> Enum.zip(parameters)
              |> Enum.map(&typecast_param/1)

            {args, stack}
          else
            Enum.split(stack, tuple_size(inputs))
          end

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

        # TODO: How should we handle gas for host functions? Does gas price
        # get passed in? Do we default to a gas value? Gas needs to be updated
        # instead of just getting passed through
        if !is_binary(return_val) do
          {outputs, {vm, gas, stack}}
        else
          {outputs, {vm, gas, [return_val | stack]}}
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

  # Begin i32 Instructions =====================================================

  defop i32_const(immediates: [i32]) do
    {ctx, gas + Gas.cost(:i32_const), [<<i32::integer-32-little>> | stack]}
  end

  defop i32_add(<<a::integer-32-little>>, <<b::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_add), [<<(a + b)::integer-32-little>> | stack]}
  end

  defop i32_sub(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_sub), [<<(a - b)::integer-32-little>> | stack]}
  end

  defop i32_mul(<<a::integer-32-little>>, <<b::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_mul), [<<(a * b)::integer-32-little>> | stack]}
  end

  defop i32_div_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    if b == 0, do: trap("Divide by zero in i32.div_s")
    if a / b >= 2147483648, do: trap("Out of bounds in i32.div_s")

    res = <<trunc(a / b)::integer-32-little-signed>>

    {ctx, gas + Gas.cost(:i32_div_s), [res | stack]}
  end

  defop i32_div_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    if b == 0, do: trap("Divide by zero in i32.div_s")

    res = <<trunc(a / b)::integer-32-little>>

    {ctx, gas + Gas.cost(:i32_div_u), [res | stack]}
  end

  defop i32_rem_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    if b == 0, do: trap("Divide by zero in i32.rem_s")

    {ctx, gas + Gas.cost(:i32_rem_s), [<<rem(a, b)::integer-32-little-signed>> | stack]}
  end

  defop i32_rem_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    if b == 0, do: trap("Divide by zero in i32.rem_u")

    {ctx, gas + Gas.cost(:i32_rem_u), [<<rem(a, b)::integer-32-little>> | stack]}
  end

  defop i32_rotl(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_rotl), [<<rotl(b, a)::integer-32-little>> | stack]}
  end

  defop i32_rotr(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_rotr), [<<rotr(b, a)::integer-32-little>> | stack]}
  end

  defop i32_and(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_and), [<<(a &&& b)::integer-32-little>> | stack]}
  end

  defop i32_or(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_or), [<<(a ||| b)::integer-32-little>> | stack]}
  end

  defop i32_xor(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_xor), [<<bxor(a, b)::integer-32-little>> | stack]}
  end

  defop i32_shl(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_shl), [<<(a <<< b)::integer-32-little>> | stack]}
  end

  defop i32_shr_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:i32_shr_u), [<<(a >>> b)::integer-32-little>> | stack]}
  end

  defop i32_shr_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    {ctx, gas + Gas.cost(:i32_shr_s), [<<(a >>> b)::integer-32-little-signed>> | stack]}
  end

  defop i32_eq(a, b) do
    result = if a === b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_eq), [result | stack]}
  end

  defop i32_ne(a, b) do
    result = if a !== b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_ne), [result | stack]}
  end

  defop i32_eqz(a) do
    result = if a === <<0, 0, 0, 0>>, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_eqz), [result | stack]}
  end

  defop i32_lt_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_lt_u), [result | stack]}
  end

  defop i32_gt_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_gt_u), [result | stack]}
  end

  defop i32_le_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_le_u), [result | stack]}
  end

  defop i32_ge_u(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_ge_u), [result | stack]}
  end

  defop i32_le_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_le_s), [result | stack]}
  end

  defop i32_ge_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_ge_s), [result | stack]}
  end

  defop i32_lt_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_lt_s), [result | stack]}
  end

  defop i32_gt_s(<<b::integer-32-little-signed>>, <<a::integer-32-little-signed>>) do
    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i32_gt_s), [result | stack]}
  end

  defop i32_popcnt(i32) do
    count =
      (for <<bit::1 <- i32 >>, do: bit)
      |> Enum.reject(& &1 !== 1)
      |> length()

    {ctx, gas + Gas.cost(:i32_popcnt, count), [<<count::integer-32-little>> | stack]}
  end

  defop i32_ctz(i32) do
    num_zeros =
      (for <<bit::1 <- i32 >>, do: bit)
      |> trailing_zeros()

    {ctx, gas + Gas.cost(:i32_ctz, num_zeros), [<<num_zeros::integer-32-little>> | stack]}
  end

  defop i32_clz(i32) do
    num_zeros =
      (for <<bit::1 <- i32 >>, do: bit)
      |> leading_zeros()

    {ctx, gas + Gas.cost(:i32_clz, num_zeros), [<<num_zeros::integer-32-little>> | stack]}
  end

  defop i32_load(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

    i32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    {ctx, gas + Gas.cost(:i32_load), [i32 | stack]}
  end

  defop i32_load8_s(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

    i8bin =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    <<i8::integer-8-little-signed>> = i8bin

    sign = if i8 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i32_load8_s), [i8bin <> <<sign, sign, sign>> | stack]}
  end

  defop i32_load16_s(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

    i16bin =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    <<i16::integer-16-little-signed>> = i16bin

    sign = if i16 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i32_load16_s), [i16bin <> <<sign, sign>> | stack]}
  end

  defop i32_load8_u(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

    i8 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    {ctx, gas + Gas.cost(:i32_load8_u), [i8 <> <<0, 0, 0>> | stack]}
  end

  defop i32_load16_u(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

    i16 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    {ctx, gas + Gas.cost(:i32_load16_u), [i16 <> <<0, 0>> | stack]}
  end

  defop i32_store(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i32_store), stack}
  end

  defop i32_store8(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

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

  defop i32_store16(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx

    # TODO: Should this be the first memory in the module? Can this reference an imported memory?
    mem_addr = hd(frame.module.memaddrs)

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

  defop i32_trunc_u_f32(<<f32::float-32-little>>) do
    {ctx, gas + Gas.cost(:i32_trunc_u_f32), [<<trunc(f32)::integer-32-little>> | stack]}
  end

  defop i32_trunc_s_f32(<<f32::float-32-little>>) do
    {ctx, gas + Gas.cost(:i32_trunc_s_f32), [<<trunc(f32)::integer-32-little-signed>> | stack]}
  end

  defop i32_trunc_u_f64(<<f64::float-64-little>>) do
    {ctx, gas + Gas.cost(:i32_trunc_u_f32), [<<trunc(f64)::integer-32-little>> | stack]}
  end

  defop i32_trunc_s_f64(<<f64::float-64-little>>) do
    {ctx, gas + Gas.cost(:i32_trunc_s_f64), [<<trunc(f64)::integer-32-little-signed>> | stack]}
  end

  # We don't actually need to do anything here, the value is already in binary,
  # we'll just read it in as a float in the next instruction that uses this value.
  defop i32_reinterpret_f32 do
    {ctx, gas + Gas.cost(:i32_reinterpret_f32), stack}
  end

  defop i32_wrap_i64(<<i32::bytes-size(4), _rest::binary>>) do
    {ctx, gas + Gas.cost(:i32_wrap_i64), [i32 | stack]}
  end

  # End i32 Instructions =======================================================
  # Begin i64 Instructions =====================================================

  defop i64_const(immediates: [i64]) do
    {ctx, gas + Gas.cost(:i64_const), [<<i64::integer-64-little>> | stack]}
  end

  defop i64_add(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_add), [<<(a + b)::integer-64-little>> | stack]}
  end

  defop i64_sub(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_sub), [<<(a - b)::integer-64-little>> | stack]}
  end

  defop i64_mul(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_mul), [<<(a * b)::integer-64-little>> | stack]}
  end

  defop i64_div_s(<<b::integer-64-little-signed>>, <<a::integer-64-little-signed>>) do
    if b == 0, do: trap("Divide by zero in i64.div_s")
    if a / b == 9.223372036854776e18, do: trap("Out of bounds in i64.div_s")

    {ctx, gas + Gas.cost(:i64_div_s), [<<trunc(a / b)::integer-64-little-signed>> | stack]}
  end

  defop i64_div_u(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    if b == 0, do: trap("Divide by zero in i64.div_u")

    {ctx, gas + Gas.cost(:i64_div_u), [<<trunc(a / b)::integer-64-little>> | stack]}
  end

  defop i64_rem_s(<<b::integer-64-little-signed>>, <<a::integer-64-little-signed>>) do
    if b == 0, do: trap("Divide by zero in i64.rem_s")

    {ctx, gas + Gas.cost(:i64_rem_s), [<<rem(a, b)::integer-64-little-signed>> | stack]}
  end

  defop i64_rem_u(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    if b == 0, do: trap("Divide by zero in i64.rem_u")

    {ctx, gas + Gas.cost(:i64_rem_u), [<<rem(a, b)::integer-64-little>> | stack]}
  end

  defop i64_rotl(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_rotl), [<<rotl(b, a)::integer-64-little>> | stack]}
  end

  defop i64_rotr(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_rotr), [<<rotr(b, a)::integer-64-little>> | stack]}
  end

  defop i64_and(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_and), [<<(a &&& b)::integer-64-little>> | stack]}
  end

  defop i64_or(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_or), [<<(a ||| b)::integer-64-little>> | stack]}
  end

  defop i64_xor(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_xor), [<<bxor(a, b)::integer-64-little>> | stack]}
  end

  defop i64_shl(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_shl), [<<(a <<< b)::integer-64-little>> | stack]}
  end

  defop i64_shr_u(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:i64_shr_u), [<<(a >>> b)::integer-64-little>> | stack]}
  end

  defop i64_shr_s(<<b::integer-64-little-signed>>, <<a::integer-64-little-signed>>) do
    {ctx, gas + Gas.cost(:i64_shr_s), [<<(a >>> b)::integer-64-little-signed>> | stack]}
  end

  defop i64_eq(b, a) do
    result = if a === b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_eq), [result | stack]}
  end

  defop i64_ne(b, a) do
    result = if a !== b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_eq), [result | stack]}
  end

  defop i64_eqz(<<a::integer-64-little>>) do
    result = if a === 0, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_eqz), [result| stack]}
  end

  defop i64_lt_u(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_lt_u), [result | stack]}
  end

  defop i64_gt_u(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_gt_u), [result | stack]}
  end

  defop i64_le_u(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_le_u), [result | stack]}
  end

  defop i64_ge_u(<<b::integer-64-little>>, <<a::integer-64-little>>) do
    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_ge_u), [result | stack]}
  end

  defop i64_le_s(<<b::integer-64-little-signed>>, <<a::integer-64-little-signed>>) do
    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_le_s), [result | stack]}
  end

  defop i64_ge_s(<<b::integer-64-little-signed>>, <<a::integer-64-little-signed>>) do
    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_ge_s), [result | stack]}
  end

  defop i64_lt_s(<<b::integer-64-little-signed>>, <<a::integer-64-little-signed>>) do
    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_lt_s), [result | stack]}
  end

  defop i64_gt_s(<<b::integer-64-little-signed>>, <<a::integer-64-little-signed>>) do
    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:i64_gt_s), [result | stack]}
  end

  defop i64_popcnt(i64) do
    count =
      (for <<bit::1 <- i64 >>, do: bit)
      |> Enum.reject(& &1 !== 1)
      |> length()

    {ctx, gas + Gas.cost(:i64_popcnt, count), [<<count::integer-64-little>> | stack]}
  end

  defop i64_clz(i64) do
    num_zeros =
      (for <<bit::1 <- i64 >>, do: bit)
      |> leading_zeros()

    {ctx, gas + Gas.cost(:i64_clz, num_zeros), [<<num_zeros::integer-64-little>> | stack]}
  end

  defop i64_ctz(i64) do
    num_zeros =
      (for <<bit::1 <- i64 >>, do: bit)
      |> trailing_zeros()

    {ctx, gas + Gas.cost(:i64_ctz, num_zeros), [<<num_zeros::integer-64-little>> | stack]}
  end

  defop i64_load(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    i64 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 8)

    {ctx, gas + Gas.cost(:i64_load), [i64 | stack]}
  end

  defop i64_load8_s(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    i8 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    sign = if i8 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_load8_s), [i8 <> <<sign, sign, sign, sign, sign, sign, sign>> | stack]}
  end

  defop i64_load16_s(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    i16 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    sign = if i16 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_load16_s), [i16 <> <<sign, sign, sign, sign, sign, sign>> | stack]}
  end

  defop i64_load32_s(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    i32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    sign = if i32 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_load32_s), [i32 <> <<sign, sign, sign, sign>> | stack]}
  end

  defop i64_load8_u(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    i8 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 1)

    {ctx, gas + Gas.cost(:i64_load8_u), [i8 <> <<0, 0, 0, 0, 0, 0, 0>> | stack]}
  end

  defop i64_load16_u(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    i16 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 2)

    {ctx, gas + Gas.cost(:i64_load16_u), [i16 <> <<0, 0, 0, 0, 0, 0>> | stack]}
  end

  defop i64_load32_u(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    i32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    {ctx, gas + Gas.cost(:i64_load32_u), [i32 <> <<0, 0, 0, 0>> | stack]}
  end

  defop i64_store(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store), stack}
  end

  defop i64_store8(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    <<i8::bytes-size(1), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i8)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store8), stack}
  end

  defop i64_store16(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    <<i16::bytes-size(2), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i16)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store16), stack}
  end

  defop i64_store32(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    <<i32::bytes-size(4), _rest::binary>> = value

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, i32)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:i64_store32), stack}
  end

  defop i64_trunc_u_f32(<<f32::float-32-little>>) do
    {ctx, gas + Gas.cost(:i64_trunc_u_f32), [<<trunc(f32)::integer-64-little>> | stack]}
  end

  defop i64_trunc_s_f32(<<f32::float-32-little>>) do
    {ctx, gas + Gas.cost(:i64_trunc_s_f32), [<<trunc(f32)::integer-64-little-signed>> | stack]}
  end

  defop i64_trunc_u_f64(<<f64::float-64-little>>) do
    {ctx, gas + Gas.cost(:i64_trunc_u_f64), [<<trunc(f64)::integer-64-little>> | stack]}
  end

  defop i64_trunc_s_f64(<<f64::float-64-little>>) do
    {ctx, gas + Gas.cost(:i64_trunc_s_f64), [<<trunc(f64)::integer-64-little-signed>> | stack]}
  end

  defop i64_extend_u_i32(i32) do
    {ctx, gas + Gas.cost(:i64_extend_u_i32), [i32 <> <<0, 0, 0, 0>> | stack]}
  end

  defop i64_extend_s_i32(i32a) do
    <<i32::integer-32-little-signed>> = i32a

    sign = if i32 >= 0, do: 0, else: 255

    {ctx, gas + Gas.cost(:i64_extend_s_i32), [i32a <> <<sign, sign, sign, sign>> | stack]}
  end

  defop i64_reinterpret_f64 do
    {ctx, gas + Gas.cost(:i64_reinterpret_f32), stack}
  end

  # End i64 Instructions =======================================================
  # Begin f32 Instructions =====================================================

  defop f32_const(immediates: [f32]) do
    {ctx, gas + Gas.cost(:f32_const), [<<f32::float-32-little>> | stack]}
  end

  defop f32_lt(<<b::float-32-little>>, <<a::float-32-little>>) do
    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_lt), [result | stack]}
  end

  defop f32_le(<<b::float-32-little>>, <<a::float-32-little>>) do
    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_le), [result | stack]}
  end

  defop f32_ge(<<b::float-32-little>>, <<a::float-32-little>>) do
    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_ge), [result | stack]}
  end

  defop f32_gt(<<b::float-32-little>>, <<a::float-32-little>>) do
    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_gt), [result | stack]}
  end

  defop f32_add(<<b::float-32-little>>, <<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_add), [<<(a + b)::float-32-little>> | stack]}
  end

  defop f32_sub(<<b::float-32-little>>, <<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_sub), [<<(a - b)::float-32-little>> | stack]}
  end

  defop f32_mul(<<b::float-32-little>>, <<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_mul), [<<(a * b)::float-32-little>> | stack]}
  end

  defop f32_div(<<b::float-32-little>>, <<a::float-32-little>>) do
    if b == 0 do
      trap("Divide by zero in f32.div")
    end

    {ctx, gas + Gas.cost(:f32_div), [<<(a / b)::float-32-little>> | stack]}
  end

  defop f32_sqrt(<<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_sqrt), [<<:math.sqrt(a)::float-32-little>> | stack]}
  end

  defop f32_nearest(<<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_nearest), [<<round(a)::float-32-little>> | stack]}
  end

  defop f32_trunc(<<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_trunc), [<<trunc(a)::float-32-little>> | stack]}
  end

  defop f32_floor(<<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_floor), [<<Float.floor(a)::float-32-little>> | stack]}
  end

  defop f32_ceil(<<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_ceil), [<<Float.ceil(a)::float-32-little>> | stack]}
  end

  defop f32_neg(<<a::float-32-little>>) do
    result = if a == 0.0, do: 0.0, else: a * -1

    {ctx, gas + Gas.cost(:f32_neg), [<<result::float-32-little>> | stack]}
  end

  defop f32_abs(<<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_abs), [<<abs(a)::float-32-little>> | stack]}
  end

  defop f32_min(<<b::float-32-little>>, <<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_min), [<<min(a, b)::float-32-little>> | stack]}
  end

  defop f32_max(<<b::float-32-little>>, <<a::float-32-little>>) do
    {ctx, gas + Gas.cost(:f32_max), [<<max(a, b)::float-32-little>> | stack]}
  end

  defop f32_load(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    f32 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 4)

    {ctx, gas + Gas.cost(:f32_load), [f32 | stack]}
  end

  defop f32_store(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:f32_store), stack}
  end

  defop f32_eq(a, b) do
    result = if a === b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_eq), [result | stack]}
  end

  defop f32_ne(a, b) do
    result = if a !== b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f32_eq), [result | stack]}
  end

  defop f32_copysign(<<b::float-32-little>>, <<a::float-32-little>>) do
    magnitude = abs(a)
    sign = if b >= 0, do: 1, else: -1

    result = magnitude * sign

    # This needs to be here because of a weird bug (?) where 0.0 * -1 would be
    # <<0, 0, 0, 128>> instead of <<0, 0, 0, 0>>, even though both were 0.0
    result = if result == 0.0, do: 0.0, else: result

    {ctx, gas + Gas.cost(:f32_copysign), [<<result::float-32-little>> | stack]}
  end

  defop f32_convert_s_i32(<<a::integer-32-little-signed>>) do
    {ctx, gas + Gas.cost(:f32_convert_s_i32), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  defop f32_convert_u_i32(<<a::integer-32-little>>) do
    {ctx, gas + Gas.cost(:f32_convert_u_i32), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  defop f32_convert_s_i64(<<a::integer-64-little-signed>>) do
    {ctx, gas + Gas.cost(:f32_convert_s_i64), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  defop f32_convert_u_i64(<<a::integer-64-little>>) do
    {ctx, gas + Gas.cost(:f32_convert_u_i64), [<<(a * 1.0)::float-32-little>> | stack]}
  end

  # TODO: Revisit this -- it's a naive solution that has a few issues (can
  # break with very large numbers)
  defop f32_demote_f64(<<f64::float-64-little>>) do
    {ctx, gas + Gas.cost(:f32_demote_f64), [<<f64::float-32-little>> | stack]}
  end

  defop f32_reinterpret_i32(a) do
    {ctx, gas + Gas.cost(:f32_reinterpret_i32), [a | stack]}
  end

  # End f32 Instructions =======================================================
  # Begin f64 Instructions =====================================================

  defop f64_const(immediates: [f64]) do
    {ctx, gas + Gas.cost(:f64_const), [<<f64::float-64-little>> | stack]}
  end

  defop f64_add(<<b::float-64-little>>, <<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_add), [<<(a + b)::float-64-little>> | stack]}
  end

  defop f64_sub(<<b::float-64-little>>, <<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_sub), [<<(a - b)::float-64-little>> | stack]}
  end

  defop f64_mul(<<b::float-64-little>>, <<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_mul), [<<(a * b)::float-64-little>> | stack]}
  end

  defop f64_min(<<b::float-64-little>>, <<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_min), [<<min(a, b)::float-64-little>> | stack]}
  end

  defop f64_max(<<b::float-64-little>>, <<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_max), [<<max(a, b)::float-64-little>> | stack]}
  end

  defop f64_lt(<<b::float-64-little>>, <<a::float-64-little>>) do
    result = if a < b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_lt), [result | stack]}
  end

  defop f64_le(<<b::float-64-little>>, <<a::float-64-little>>) do
    result = if a <= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_le), [result | stack]}
  end

  defop f64_ge(<<b::float-64-little>>, <<a::float-64-little>>) do
    result = if a >= b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_ge), [result | stack]}
  end

  defop f64_gt(<<b::float-64-little>>, <<a::float-64-little>>) do
    result = if a > b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_gt), [result | stack]}
  end

  defop f64_store(value, <<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    mem =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.put_at(i32addr + offset, value)

    store_mems = List.replace_at(vm.store.mems, mem_addr, mem)
    store = Map.put(vm.store, :mems, store_mems)

    {{frame, Map.put(vm, :store, store), n}, gas + Gas.cost(:f64_store), stack}
  end

  defop f64_load(<<i32addr::integer-32-little>>, immediates: [_align, offset]) do
    {frame, vm, _n} = ctx
    mem_addr = hd(frame.module.memaddrs)

    f64 =
      vm.store.mems
      |> Enum.at(mem_addr)
      |> Memory.get_at(i32addr + offset, 8)

    {ctx, gas + Gas.cost(:f64_load), [f64 | stack]}
  end

  defop f64_eq(a, b) do
    result = if a === b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_eq), [result | stack]}
  end

  defop f64_ne(a, b) do
    result = if a !== b, do: <<1, 0, 0, 0>>, else: <<0, 0, 0, 0>>

    {ctx, gas + Gas.cost(:f64_ne), [result | stack]}
  end

  defop f64_copysign(<<b::float-64-little>>, <<a::float-64-little>>) do
    magnitude = abs(a)
    sign = if b >= 0, do: 1, else: -1

    result = if magnitude == 0.0, do: 0.0, else: magnitude * sign

    {ctx, gas + Gas.cost(:f64_copysign), [<<result::float-64-little>> | stack]}
  end

  defop f64_nearest(<<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_nearest), [<<round(a)::float-64-little>> | stack]}
  end

  defop f64_trunc(<<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_trunc), [<<trunc(a)::float-64-little>> | stack]}
  end

  defop f64_floor(<<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_floor), [<<Float.floor(a)::float-64-little>> | stack]}
  end

  defop f64_neg(<<a::float-64-little>>) do
    result = if a == 0.0, do: 0.0, else: a * -1

    {ctx, gas + Gas.cost(:f64_neg), [<<result::float-64-little>> | stack]}
  end

  defop f64_abs(<<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_abs), [<<abs(a)::float-64-little>> | stack]}
  end

  defop f64_sqrt(<<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_sqrt), [<<:math.sqrt(a)::float-64-little>> | stack]}
  end

  defop f64_ceil(<<a::float-64-little>>) do
    {ctx, gas + Gas.cost(:f64_ceil), [<<Float.ceil(a)::float-64-little>> | stack]}
  end

  defop f64_convert_s_i64(<<i64::integer-64-little-signed>>) do
    {ctx, gas + Gas.cost(:f32_convert_s_i64), [<<i64::float-64-little>> | stack]}
  end

  defop f64_convert_u_i64(<<i64::integer-64-little>>) do
    {ctx, gas + Gas.cost(:f32_convert_u_i64), [<<i64::float-64-little>> | stack]}
  end

  defop f64_convert_s_i32(<<i32::integer-32-little-signed>>) do
    {ctx, gas + Gas.cost(:f32_convert_s_i32), [<<i32::float-64-little>> | stack]}
  end

  defop f64_convert_u_i32(<<i32::integer-32-little>>) do
    {ctx, gas + Gas.cost(:f64_convert_u_i32), [<<i32::float-64-little>> | stack]}
  end

  defop f64_promote_f32(<<f32::float-32-little>>) do
    {ctx, gas + Gas.cost(:f64_promote_f32), [<<f32::float-64-little>> | stack]}
  end

  defop f64_reinterpret_i64(a) do
    {ctx, gas + Gas.cost(:f64_reinterpret_i64), [a | stack]}
  end

  # End f64 Instructions =======================================================
  # Begin Type Agnostic Instructions ===========================================

  defop call(immediates: [funcidx]) do
    {frame, vm, n} = ctx

    %{^funcidx => func_addr} = frame.module.funcaddrs

    # TODO: Maybe this shouldn't pass the existing stack in?
    {_outputs, {vm, gas, stack}} = create_frame_and_execute(vm, func_addr, frame.gas_limit, opts, gas, stack)

    {{frame, vm, n}, gas + Gas.cost(:call), stack}
  end

  defop set_global(value, immediates: [idx]) do
    {frame, vm, n} = ctx
    globals = List.replace_at(vm.globals, idx, value)

    {{frame, Map.put(vm, :globals, globals), n}, gas + Gas.cost(:set_global), stack}
  end

  defop set_local(value, immediates: [idx]) do
    {frame, vm, n} = ctx
    locals = put_elem(frame.locals, idx, value)

    {{Map.put(frame, :locals, locals), vm, n}, gas + Gas.cost(:set_local), stack}
  end

  defop get_local(immediates: [idx]) do
    {frame, _vm, _n} = ctx
    {ctx, gas + Gas.cost(:get_local), [elem(frame.locals, idx) | stack]}
  end

  defop get_global(immediates: [idx]) do
    {_frame, vm, _n} = ctx
    {ctx, gas + Gas.cost(:get_global), [Enum.at(vm.globals, idx) | stack]}
  end

  defop tee_local(immediates: [idx]) do
    {frame, vm, n} = ctx
    [value | _] = stack
    locals = put_elem(frame.locals, idx, value)

    {{Map.put(frame, :locals, locals), vm, n}, gas + Gas.cost(:tee_local), stack}
  end

  defop grow_memory(<<pages::integer-32-little>>) do
    {frame, vm, n} = ctx
    memory = Memory.grow(vm.memory, pages)
    vm = Map.put(vm, :memory, memory)

    {{frame, vm, n}, gas + Gas.cost(:grow_memory), [length(vm.memory) | stack]}
  end

  defop current_memory do
    {_frame, vm, _n} = ctx
    {ctx, gas + Gas.cost(:current_memory), [length(vm.memory.pages) | stack]}
  end

  defop loop(immediates: [_result_type]) do
    {frame, vm, n} = ctx
    labels = [{n, n} | frame.labels]
    snapshots = [stack | frame.snapshots]
    frame = Map.merge(frame, %{labels: labels, snapshots: snapshots})

    {{frame, vm, n}, gas + Gas.cost(:loop), stack}
  end

  defop block(immediates: [_result_type, end_idx]) do
    {frame, vm, n} = ctx
    labels = [{n, end_idx - 1} | frame.labels]
    snapshots = [stack | frame.snapshots]
    frame = Map.merge(frame, %{labels: labels, snapshots: snapshots})

    {{frame, vm, n}, gas + Gas.cost(:block), stack}
  end

  defop select(condition, b, a) do
    stack = if condition == <<1, 0, 0, 0>>, do: [a | stack], else: [b | stack]

    {ctx, gas + Gas.cost(:select), stack}
  end

  defop br_if(condition, immediates: [label_idx]) do
    if condition == <<1, 0, 0, 0>> do
      break_to(ctx, gas + Gas.cost(:br_if), stack, label_idx)
    else
      {ctx, gas + Gas.cost(:br_if), stack}
    end
  end

  defop drop(_) do
    {ctx, gas + Gas.cost(:drop), stack}
  end

  defop br(immediates: [label_idx]) do
    break_to(ctx, gas + Gas.cost(:br), stack, label_idx)
  end

  defop return do
    {frame, vm, _n} = ctx
    {{frame, vm, -10}, gas + Gas.cost(:return), stack}
  end

  defop unreachable do
    {ctx, gas + Gas.cost(:unreachable), stack}
  end

  defop nop do
    {ctx, gas + Gas.cost(:nop), stack}
  end

  defp instruction({frame, vm, n}, gas, [<<1, 0, 0, 0>> | stack], _opts, {:if, _type, _else_idx, end_idx}) do
    labels = [{n, end_idx} | frame.labels]
    snapshots = [stack | frame.snapshots]

    frame = Map.merge(frame, %{labels: labels, snapshots: snapshots})

    {{frame, vm, n}, gas + Gas.cost(:if), stack}
  end

  defp instruction({frame, vm, _n}, gas, [_ | stack], _opts, {:if, _type, else_idx, end_idx}) do
    next_instr = if else_idx != :none, do: else_idx, else: end_idx

    {{frame, vm, next_instr}, gas + Gas.cost(:if), stack}
  end

  # This just skips to end because the only time an "else" instruction
  # is evaluated is immediately following the execution of an "if" body, which
  # means we don't actually want to execute the "else" body. The "if" opcode
  # will jump to the body of the else branch if needed.
  defp instruction({frame, vm, _n}, gas, stack, _opts, {:else, end_idx}) do
    {{frame, vm, end_idx}, gas + Gas.cost(:else), stack}
  end

  defp instruction({%{labels: []} = frame, vm, n}, gas, stack, _opts, :end), do: {{frame, vm, n}, gas + Gas.cost(:end, true), stack}
  defp instruction({frame, vm, n}, gas, stack, _opts, :end) do
    [_ | labels] = frame.labels
    [_ | snapshots] = frame.snapshots

    {{Map.merge(frame, %{labels: labels, snapshots: snapshots}), vm, n}, gas + Gas.cost(:end, false), stack}
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

  defp rotl(number, shift), do: (number <<< shift) ||| (number >>> (0x1F &&& (32 + ~~~(shift + 1)))) &&& ~~~(0xFFFFFFFF <<< shift)
  defp rotr(number, shift), do: (number >>> shift) ||| (number <<< (0x1F &&& (32 + ~~~(-shift + 1)))) &&& ~~~(0xFFFFFFFF <<< -shift)

  def float_demote(number) do
    D.set_context(%D.Context{D.get_context | precision: 6})

    number * 10
    |> :erlang.float_to_binary([decimals: 6])
    |> D.new()
  end

  defp trap(reason), do: raise "Runtime Error -- #{reason}"

  defp trailing_zeros(bin_list) do
    bin_list
    |> Enum.reverse()
    |> leading_zeros()
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
