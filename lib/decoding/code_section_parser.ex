defmodule WaspVM.Decoder.CodeSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  require IEx

  def parse(module) do
    {count, bodies} =
      module.sections
      |> Map.get(10)
      |> LEB128.decode()

    bodies = if count > 0, do: parse_bodies(bodies), else: []

    Map.put(module, :functions, Enum.reverse(bodies))
  end

  defp parse_bodies(bodies), do: parse_bodies([], bodies)
  defp parse_bodies(parsed, <<>>), do: parsed

  defp parse_bodies(parsed, bodies) do
    {body_size, bodies} = LEB128.decode(bodies)

    <<body::bytes-size(body_size), bodies::binary>> = bodies

    {local_count, body} = LEB128.decode(body)

    {locals, body} =
      if local_count > 0 do
        parse_locals(body, local_count)
      else
        {[], body}
      end

    IO.inspect(body)

    parsed_bytecode =
      body
      |> parse_bytecode()
      |> Enum.reverse()

    body = %{locals: locals, body: parsed_bytecode, bytecode: body}

    parse_bodies([body | parsed], bodies)
  end

  defp parse_locals(bin, count), do: parse_locals([], bin, count)
  defp parse_locals(parsed, bin, 0), do: {parsed, bin}

  defp parse_locals(parsed, bin, count) do
    {ct, bin} = LEB128.decode(bin)

    <<opcode::bytes-size(1), bin::binary>> = bin

    local = %{count: ct, type: OpCodes.opcode_to_type(opcode)}

    parse_locals([local | parsed], bin, count - 1)
  end

  defp parse_bytecode(bytecode), do: parse_bytecode([], bytecode)
  defp parse_bytecode(instructions, <<>>), do: instructions

  defp parse_bytecode(instructions, bytecode) do
    <<opcode::bytes-size(1), bytecode::binary>> = bytecode

    opcode = OpCodes.encode_instr(opcode)

    {instruction, bytecode} = parse_instruction(opcode, bytecode)

    parse_bytecode([instruction | instructions], bytecode)
  end



  defp parse_instruction(:i32_store, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i32_store, alignment, offset}, rest}
  end

  defp parse_instruction(:i32_load, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i32_load, alignment, offset}, rest}

  end

  defp parse_instruction(:i32_add, bytecode) do
    {:i32_add, bytecode}
  end


  defp parse_instruction(:i64_load, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_load, alignment, offset}, rest}
  end


  defp parse_instruction(:f32_load, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:f32_load, alignment, offset}, rest}
  end

  defp parse_instruction(:f64_load, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:f32_load, alignment, offset}, rest}
  end

  defp parse_instruction(:i32_load8_s, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i32_load8_s, alignment, offset}, rest}
  end

  defp parse_instruction(:i32_load8_u, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i32_load8_u, alignment, offset}, rest}
  end

  defp parse_instruction(:i32_load16_u, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i32_load16_u, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_load8_s, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_load8_s, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_load8_u, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_load8_u, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_load16_s, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_load16_s, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_load16_u, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_load16_u, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_load32_s, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_load32_s, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_load32_u, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_load32_u, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_store, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_store, alignment, offset}, rest}
  end

  defp parse_instruction(:f32_store, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:f32_store, alignment, offset}, rest}
  end

  defp parse_instruction(:f64_store, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:f64_store, alignment, offset}, rest}
  end

  defp parse_instruction(:i32_store8, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i32_store8, alignment, offset}, rest}
  end

  defp parse_instruction(:i32_store16, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i32_store16, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_store8, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_store8, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_store16, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_store16, alignment, offset}, rest}
  end

  defp parse_instruction(:i64_store32, bytecode) do
    {alignment, rest} = LEB128.decode(bytecode)
    {offset, rest} = LEB128.decode(rest)

    {{:i64_store32, alignment, offset}, rest}
  end

  defp parse_instruction(:memory_size, bytecode) do
    {:memory_size, bytecode}
  end

  defp parse_instruction(:memory_grow, bytecode) do
    {:memory_grow, bytecode}
  end

  defp parse_instruction(:i32_const, bytecode) do
    {int_value, rest} = LEB128.decode(bytecode)

    {{:i32_const, int_value}, rest}
  end

  defp parse_instruction(:i64_const, bytecode) do
    {int_value, rest} = LEB128.decode(bytecode)

    {{:i64_const, int_value}, rest}
  end

  defp parse_instruction(:f32_const, bytecode) do
    {float_value, rest} = LEB128.decode(bytecode)

    {{:f32_const, float_value}, rest}
  end

  defp parse_instruction(:f64_const, bytecode) do
    {float_value, rest} = LEB128.decode(bytecode)

    {{:f64_const, float_value}, rest}
  end

  defp parse_instruction(:i32_eqz, bytecode) do
    {:i32_eqz, bytecode}
  end

  defp parse_instruction(:i32_eq, bytecode) do
    {:i32_eq, bytecode}
  end

  defp parse_instruction(:i32_ne, bytecode) do
    {:i32_ne, bytecode}
  end
  defp parse_instruction(:i32_lt_s, bytecode) do
    {:i32_lt_s, bytecode}
  end
  defp parse_instruction(:i32_lt_u, bytecode) do
    {:i32_lt_u, bytecode}
  end
  defp parse_instruction(:i32_gt_s, bytecode) do
    {:i32_gt_s, bytecode}
  end
  defp parse_instruction(:i32_gt_u, bytecode) do
    {:i32_gt_u, bytecode}
  end
  defp parse_instruction(:i32_le_s, bytecode) do
    {:i32_le_s, bytecode}
  end
  defp parse_instruction(:i32_le_u, bytecode) do
    {:i32_le_u, bytecode}
  end

  defp parse_instruction(:i32_ge_s, bytecode) do
    {:i32_ge_s, bytecode}
  end
  defp parse_instruction(:i32_ge_u, bytecode) do
    {:i32_ge_u, bytecode}
  end
  defp parse_instruction(:i32_clz, bytecode) do
    {:i32_clz, bytecode}
  end
  defp parse_instruction(:i32_ctz, bytecode) do
    {:i32_ctz, bytecode}
  end
  defp parse_instruction(:i32_popcnt, bytecode) do
    {:i32_popcnt, bytecode}
  end
  defp parse_instruction(:i32_add, bytecode) do
    {:i32_add, bytecode}
  end
  defp parse_instruction(:i32_sub, bytecode) do
    {:i32_sub, bytecode}
  end
  defp parse_instruction(:i32_mul, bytecode) do
    {:i32_mul, bytecode}
  end

  defp parse_instruction(:i32_div_s, bytecode) do
    {:i32_div_, bytecode}
  end
  defp parse_instruction(:i32_div_u, bytecode) do
    {:i32_div_, bytecode}
  end
  defp parse_instruction(:i32_rem_s, bytecode) do
    {:i32_rem_, bytecode}
  end
  defp parse_instruction(:i32_rem_u, bytecode) do
    {:i32_rem_, bytecode}
  end
  defp parse_instruction(:i32_add, bytecode) do
    {:i32_add, bytecode}
  end
  defp parse_instruction(:i32_or, bytecode) do
    {:i32_or, bytecode}
  end
  defp parse_instruction(:i32_xor, bytecode) do
    {:i32_xor, bytecode}
  end
  defp parse_instruction(:i32_shl, bytecode) do
    {:i32_shl, bytecode}
  end
  defp parse_instruction(:i32_shr_s, bytecode) do
    {:i32_shr_, bytecode}
  end
  defp parse_instruction(:i32_shr_u, bytecode) do
    {:i32_shr_, bytecode}
  end
  defp parse_instruction(:i32_rotl, bytecode) do
    {:i32_rotl, bytecode}
  end
  defp parse_instruction(:i32_rotr, bytecode) do
    {:i32_rotr, bytecode}
  end
  defp parse_instruction(:i64_eqz, bytecode) do
    {:i64_eqz, bytecode}
  end
  defp parse_instruction(:i64_eq, bytecode) do
    {:i64_eq, bytecode}
  end
  defp parse_instruction(:i64_ne, bytecode) do
    {:i64_ne, bytecode}
  end
  defp parse_instruction(:i64_lt_s, bytecode) do
    {:i64_lt_s, bytecode}
  end
  defp parse_instruction(:i64_lt_u, bytecode) do
    {:i64_lt_u, bytecode}
  end
  defp parse_instruction(:i64_gt_s, bytecode) do
    {:i64_gt_s, bytecode}
  end
  defp parse_instruction(:i64_gt_u, bytecode) do
    {:i64_gt_u, bytecode}
  end
  defp parse_instruction(:i64_le_s, bytecode) do
    {:i64_le_s, bytecode}
  end
  defp parse_instruction(:i64_le_u, bytecode) do
    {:i64_le_u, bytecode}
  end
  defp parse_instruction(:i64_ge_s, bytecode) do
    {:i64_ge_s, bytecode}
  end
  defp parse_instruction(:i64_ge_u, bytecode) do
    {:i64_ge_u, bytecode}
  end
  defp parse_instruction(:i64_clz, bytecode) do
    {:i64_clz, bytecode}
  end
  defp parse_instruction(:i64_ctz, bytecode) do
    {:i64_ctz, bytecode}
  end

  defp parse_instruction(:i64_popcnt, bytecode) do
    {:i64_popcnt, bytecode}
  end
  defp parse_instruction(:i64_add, bytecode) do
    {:i64_add, bytecode}
  end
  defp parse_instruction(:i64_sub, bytecode) do
    {:i64_sub, bytecode}
  end
  defp parse_instruction(:i64_mul, bytecode) do
    {:i64_mul, bytecode}
  end
  defp parse_instruction(:i64_div_s, bytecode) do
    {:i64_div_s, bytecode}
  end
  defp parse_instruction(:i64_div_u, bytecode) do
    {:i64_div_u, bytecode}
  end
  defp parse_instruction(:i64_rem_s, bytecode) do
    {:i64_rem_s, bytecode}
  end
  defp parse_instruction(:i64_rem_u, bytecode) do
    {:i64_rem_u, bytecode}
  end
  defp parse_instruction(:i64_add, bytecode) do
    {:i64_add, bytecode}
  end
  defp parse_instruction(:i64_or, bytecode) do
    {:i64_or, bytecode}
  end
  defp parse_instruction(:i64_xor, bytecode) do
    {:i64_xor, bytecode}
  end
  defp parse_instruction(:i64_shl, bytecode) do
    {:i64_shl, bytecode}
  end
  defp parse_instruction(:i64_shr_s, bytecode) do
    {:i64_shr_s, bytecode}
  end
  defp parse_instruction(:i64_shr_u, bytecode) do
    {:i64_shr_u, bytecode}
  end
  defp parse_instruction(:i64_rotl, bytecode) do
    {:i64_rotl, bytecode}
  end
  defp parse_instruction(:i64_rotr, bytecode) do
    {:i64_rotr, bytecode}
  end
  defp parse_instruction(:f32_eq, bytecode) do
    {:f32_eq, bytecode}
  end
  defp parse_instruction(:f32_ne, bytecode) do
    {:f32_ne, bytecode}
  end
  defp parse_instruction(:f32_lt, bytecode) do
    {:f32_lt, bytecode}
  end
  defp parse_instruction(:f32_gt, bytecode) do
    {:f32_gt, bytecode}
  end
  defp parse_instruction(:f32_le, bytecode) do
    {:f32_le, bytecode}
  end
  defp parse_instruction(:f32_ge, bytecode) do
    {:f32_ge, bytecode}
  end
  defp parse_instruction(:f32_abs, bytecode) do
    {:f32_abs, bytecode}
  end
  defp parse_instruction(:f32_neg, bytecode) do
    {:f32_neg, bytecode}
  end
  defp parse_instruction(:f32_ceil, bytecode) do
    {:f32_ceil, bytecode}
  end
  defp parse_instruction(:f32_floor, bytecode) do
    {:f32_floor, bytecode}
  end
  defp parse_instruction(:f32_trunc, bytecode) do
    {:f32_trunc, bytecode}
  end
  defp parse_instruction(:f32_nearest, bytecode) do
    {:f32_nearest, bytecode}
  end
  defp parse_instruction(:f32_sqrt, bytecode) do
    {:f32_sqrt, bytecode}
  end
  defp parse_instruction(:f32_add, bytecode) do
    {:f32_add, bytecode}
  end
  defp parse_instruction(:f32_sub, bytecode) do
    {:f32_sub, bytecode}
  end
  defp parse_instruction(:f32_mul, bytecode) do
    {:f32_mul, bytecode}
  end
  defp parse_instruction(:f32_div, bytecode) do
    {:f32_div, bytecode}
  end
  defp parse_instruction(:f32_min, bytecode) do
    {:f32_min, bytecode}
  end
  defp parse_instruction(:f32_max, bytecode) do
    {:f32_max, bytecode}
  end
  defp parse_instruction(:f32_copysign, bytecode) do
    {:f32_copysign, bytecode}
  end
  defp parse_instruction(:f64_eq, bytecode) do
    {:f64_eq, bytecode}
  end
  defp parse_instruction(:f64_ne, bytecode) do
    {:f64_ne, bytecode}
  end
  defp parse_instruction(:f64_lt, bytecode) do
    {:f64_lt, bytecode}
  end
  defp parse_instruction(:f64_gt, bytecode) do
    {:f64_gt, bytecode}
  end
  defp parse_instruction(:f64_le, bytecode) do
    {:f64_le, bytecode}
  end
  defp parse_instruction(:f64_ge, bytecode) do
    {:f64_ge, bytecode}
  end
  defp parse_instruction(:f64_abs, bytecode) do
    {:f64_abs, bytecode}
  end
  defp parse_instruction(:f64_neg, bytecode) do
    {:f64_neg, bytecode}
  end
  defp parse_instruction(:f64_ceil, bytecode) do
    {:f64_ceil, bytecode}
  end
  defp parse_instruction(:f64_floor, bytecode) do
    {:f64_floor, bytecode}
  end
  defp parse_instruction(:f64_trunc, bytecode) do
    {:f64_trunc, bytecode}
  end
  defp parse_instruction(:f64_nearest, bytecode) do
    {:f64_nearest, bytecode}
  end
  defp parse_instruction(:f64_sqrt, bytecode) do
    {:f64_sqrt, bytecode}
  end
  defp parse_instruction(:f64_add, bytecode) do
    {:f64_add, bytecode}
  end
  defp parse_instruction(:f64_sub, bytecode) do
    {:f64_sub, bytecode}
  end
  defp parse_instruction(:f64_mul, bytecode) do
    {:f64_mul, bytecode}
  end
  defp parse_instruction(:f64_div, bytecode) do
    {:f64_div, bytecode}
  end
  defp parse_instruction(:f64_min, bytecode) do
    {:f64_min, bytecode}
  end
  defp parse_instruction(:f64_max, bytecode) do
    {:f64_max, bytecode}
  end
  defp parse_instruction(:f64_copysign, bytecode) do
    {:f64_copysign, bytecode}
  end
  defp parse_instruction(:i32_wrap_i64, bytecode) do
    {:i32_wrap_i64, bytecode}
  end
  defp parse_instruction(:i32_trunc_s_f32, bytecode) do
    {:i32_trunc_s_f32, bytecode}
  end
  defp parse_instruction(:i32_trunc_u_f32, bytecode) do
    {:i32_trunc_u_f32, bytecode}
  end
  defp parse_instruction(:i32_trunc_s_f64, bytecode) do
    {:i32_trunc_s_f64, bytecode}
  end
  defp parse_instruction(:i32_trunc_u_f64, bytecode) do
    {:i32_trunc_u_f64, bytecode}
  end
  defp parse_instruction(:i64_extend_s_i32, bytecode) do
    {:i64_extend_s_i32, bytecode}
  end
  defp parse_instruction(:i64_extend_u_i32, bytecode) do
    {:i64_extend_u_i32, bytecode}
  end
  defp parse_instruction(:i64_trunc_s_f32, bytecode) do
    {:i64_trunc_s_f32, bytecode}
  end
  defp parse_instruction(:i64_trunc_u_f32, bytecode) do
    {:i64_trunc_u_f32, bytecode}
  end
  defp parse_instruction(:i64_trunc_s_f64, bytecode) do
    {:i64_trunc_s_f64, bytecode}
  end
  defp parse_instruction(:i64_trunc_u_f64, bytecode) do
    {:i64_trunc_u_f64, bytecode}
  end
  defp parse_instruction(:f32_convert_s_i32, bytecode) do
    {:f32_convert_s_i32, bytecode}
  end
  defp parse_instruction(:f32_convert_u_i32, bytecode) do
    {:f32_convert_u_i32, bytecode}
  end
  defp parse_instruction(:f32_convert_s_i64, bytecode) do
    {:f32_convert_s_i64, bytecode}
  end
  defp parse_instruction(:f32_convert_u_i64, bytecode) do
    {:f32_convert_u_i64, bytecode}
  end
  defp parse_instruction(:f32_demote_f64, bytecode) do
    {:f32_demote_f64, bytecode}
  end
  defp parse_instruction(:f64_convert_s_i32, bytecode) do
    {:f64_convert_s_i32, bytecode}
  end
  defp parse_instruction(:f64_convert_u_i32, bytecode) do
    {:f64_convert_u_i32, bytecode}
  end
  defp parse_instruction(:f64_convert_s_i64, bytecode) do
    {:f64_convert_s_i64, bytecode}
  end
  defp parse_instruction(:f64_convert_u_i64, bytecode) do
    {:f64_convert_u_i64, bytecode}
  end
  defp parse_instruction(:f64_promote_f32, bytecode) do
    {:f64_promote_f32, bytecode}
  end
  defp parse_instruction(:i32_reinterpret_f32, bytecode) do
    {:i32_reinterpret_f32, bytecode}
  end
  defp parse_instruction(:i64_reinterpret_f64, bytecode) do
    {:i64_reinterpret_f64, bytecode}
  end
  defp parse_instruction(:f32_reinterpret_i32, bytecode) do
    {:f32_reinterpret_i32, bytecode}
  end
  defp parse_instruction(:f64_reinterpret_i64, bytecode) do
    {:f64_reinterpret_i64, bytecode}
  end

## Parametric Intructions
  defp parse_instruction(:drop, bytecode) do
    {:drop, bytecode}
  end

  defp parse_instruction(:select, bytecode) do
    {:select, bytecode}
  end

### Control Instructions
   defp parse_instruction(:return, bytecode) do
     {:return, bytecode}
   end

   defp parse_instruction(:br, bytecode) do
     {label_index, rest} = LEB128.decode(bytecode)

     {{:br, label_index}, rest}
   end

   defp parse_instruction(:br_if, bytecode) do
     {label_index, rest} = LEB128.decode(bytecode)

     {{:br_if, label_index}, rest}
   end

   defp parse_instruction(:nop, bytecode) do
     {:nop, bytecode}
   end

   #Needs Revisitng
   defp parse_instruction(:call, bytecode) do
     {function_index, rest} = LEB128.decode(bytecode)

     {{:call, function_index}, rest}
   end

   defp parse_instruction(:call_indirect, bytecode) do
     {type_index, rest} = LEB128.decode(bytecode)

     {{:call, type_index}, rest}
   end

   defp parse_instruction(:br_table, bytecode) do
     #NEEDS VERIFICATION
     {label_indices, rest} = LEB128.decode(bytecode)
     {label_index, rest} = LEB128.decode(bytecode)

     {{:br_table, label_indices, label_index}, rest}
   end

   #Structured Instruction
   defp parse_instruction(:block, bytecode) do
     #NEEDS VERIFICATION
     {result_type, rest} = LEB128.decode(bytecode)
     {instructions, rest} = LEB128.decode(rest)
     {{:block, result_type, instructions}, rest}
   end

   defp parse_instruction(:loop, bytecode) do
     #NEEDS VERIFICATION
     {result_type, rest} = LEB128.decode(bytecode)
     {instructions, rest} = LEB128.decode(rest)
     {{:loop, result_type, instructions}, rest}
   end

   defp parse_instruction(:if, bytecode) do
     #NEEDS VERIFICATION
     {result_type, rest} = LEB128.decode(bytecode)
     {consequence, rest} = LEB128.decode(rest)
     {alternate, rest} = LEB128.decode(rest)
     {{:if, result_type, consequence, alternate}, rest}
   end

   defp parse_instruction(:unreachable, bytecode) do
     {:unreachable, bytecode}
   end


  defp parse_instruction(:end, bytecode) do
    {:end, bytecode}
  end

  defp parse_instruction(:get_local, bytecode) do
    {local_index, rest} = LEB128.decode(bytecode)

    {{:get_local, local_index}, rest}

  end

  defp parse_instruction(:set_local, bytecode) do
    {local_index, rest} = LEB128.decode(bytecode)

    {{:set_local, local_index}, rest}
  end

  defp parse_instruction(:tee_local, bytecode) do
    {local_index, rest} = LEB128.decode(bytecode)

    {{:tee_local, local_index}, rest}
  end

  defp parse_instruction(:set_global, bytecode) do
    {global_index, rest} = LEB128.decode(bytecode)

    {{:set_global, global_index}, rest}
  end

  defp parse_instruction(:get_global, bytecode) do
    {global_index, rest} = LEB128.decode(bytecode)

    {{:get_global, global_index}, rest}
  end



end
