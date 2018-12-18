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

    parsed_bytecode =
      body
      |> parse_bytecode()
      |> Enum.reverse()

    body = %{locals: locals, body: parsed_bytecode}

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

    {instruction, bytecode} =
      opcode
      |> OpCodes.encode_instr()
      |> parse_instruction(bytecode)

    parse_bytecode([instruction | instructions], bytecode)
  end

  # Needs revisiting
  defp parse_instruction(:call_indirect, bytecode) do
    {type_index, rest} = LEB128.decode(bytecode)

    {{:call, type_index}, rest}
  end

  defp parse_instruction(:br_table, bytecode) do
    {target_count, rest} = LEB128.decode(bytecode)
    {target_table, rest} = get_entries(rest, target_count)
    {default_target, rest} = LEB128.decode(rest)

    {{:br_table, target_table, default_target}, rest}
  end

#################### NOT COMPLETED ###############################
  # i32_and
  # i64_and
  defp parse_instruction(:if, bytecode), do: parse_block_type_instruction(:if, bytecode)
  defp parse_instruction(:block, bytecode), do: parse_block_type_instruction(:block, bytecode)
  defp parse_instruction(:loop, bytecode), do: parse_block_type_instruction(:loop, bytecode)
  defp parse_instruction(:call, bytecode), do: get_single_value(:call, bytecode)
  defp parse_instruction(:br, bytecode), do: get_single_value(:br, bytecode)
  defp parse_instruction(:br_if, bytecode), do: get_single_value(:br_if, bytecode)
  defp parse_instruction(:i32_load8_s, bytecode), do: get_two_values(:i32_load8_s, bytecode)
  defp parse_instruction(:i32_load8_u, bytecode), do: get_two_values(:i32_load8_u, bytecode)
  defp parse_instruction(:i32_load16_u, bytecode), do: get_two_values(:i32_load16_u, bytecode)
  defp parse_instruction(:i64_load8_s, bytecode), do: get_two_values(:i64_load8_s, bytecode)
  defp parse_instruction(:i64_load8_u, bytecode), do: get_two_values(:i64_load8_u, bytecode)
  defp parse_instruction(:i64_load16_s, bytecode), do: get_two_values(:i64_load16_s, bytecode)
  defp parse_instruction(:i64_load16_u, bytecode), do: get_two_values(:i64_load16_u, bytecode)
  defp parse_instruction(:i64_load32_s, bytecode), do: get_two_values(:i64_load32_s, bytecode)
  defp parse_instruction(:i64_load32_u, bytecode), do: get_two_values(:i64_load32_u, bytecode)
  defp parse_instruction(:i32_store8, bytecode), do: get_two_values(:i32_store8, bytecode)
  defp parse_instruction(:i32_store16, bytecode), do: get_two_values(:i32_store16, bytecode)
  defp parse_instruction(:i64_store8, bytecode), do: get_two_values(:i64_store8, bytecode)
  defp parse_instruction(:i64_store16, bytecode), do: get_two_values(:i64_store16, bytecode)
  defp parse_instruction(:i64_store32, bytecode), do: get_two_values(:i64_store32, bytecode)

  defp parse_instruction(:i32_shl, bytecode), do: {:i32_shl, bytecode}
  defp parse_instruction(:i32_shr_u, bytecode), do: {:i32_shr_, bytecode}
  defp parse_instruction(:i32_rotl, bytecode), do: {:i32_rotl, bytecode}
  defp parse_instruction(:i32_rotr, bytecode), do: {:i32_rotr, bytecode}
  defp parse_instruction(:i32_lt_u, bytecode), do: {:i32_lt_u, bytecode}
  defp parse_instruction(:i32_gt_u, bytecode), do: {:i32_gt_u, bytecode}
  defp parse_instruction(:i32_le_u, bytecode), do: {:i32_le_u, bytecode}
  defp parse_instruction(:i32_ge_u, bytecode), do: {:i32_ge_u, bytecode}
  defp parse_instruction(:i64_lt_u, bytecode), do: {:i64_lt_u, bytecode}
  defp parse_instruction(:i64_gt_u, bytecode), do: {:i64_gt_u, bytecode}
  defp parse_instruction(:i64_le_u, bytecode), do: {:i64_le_u, bytecode}
  defp parse_instruction(:i64_ge_u, bytecode), do: {:i64_ge_u, bytecode}
  defp parse_instruction(:i64_clz, bytecode), do: {:i64_clz, bytecode}
  defp parse_instruction(:i64_ctz, bytecode), do: {:i64_ctz, bytecode}

  defp parse_instruction(:i64_shl, bytecode), do: {:i64_shl, bytecode}
  defp parse_instruction(:i64_rotl, bytecode), do: {:i64_rotl, bytecode}
  defp parse_instruction(:i64_rotr, bytecode), do: {:i64_rotr, bytecode}
  defp parse_instruction(:f32_eq, bytecode), do: {:f32_eq, bytecode}
  defp parse_instruction(:f32_ne, bytecode), do: {:f32_ne, bytecode}
  defp parse_instruction(:f32_lt, bytecode), do: {:f32_lt, bytecode}
  defp parse_instruction(:f32_gt, bytecode), do: {:f32_gt, bytecode}
  defp parse_instruction(:f32_le, bytecode), do: {:f32_le, bytecode}
  defp parse_instruction(:f32_ge, bytecode), do: {:f32_ge, bytecode}
  defp parse_instruction(:f32_abs, bytecode), do: {:f32_abs, bytecode}
  defp parse_instruction(:f32_neg, bytecode), do: {:f32_neg, bytecode}
  defp parse_instruction(:f32_ceil, bytecode), do: {:f32_ceil, bytecode}
  defp parse_instruction(:f32_floor, bytecode), do: {:f32_floor, bytecode}
  defp parse_instruction(:f32_trunc, bytecode), do: {:f32_trunc, bytecode}
  defp parse_instruction(:f32_nearest, bytecode), do: {:f32_nearest, bytecode}




  defp parse_instruction(:f32_copysign, bytecode), do: {:f32_copysign, bytecode}
  defp parse_instruction(:f64_eq, bytecode), do: {:f64_eq, bytecode}
  defp parse_instruction(:f64_ne, bytecode), do: {:f64_ne, bytecode}
  defp parse_instruction(:f64_lt, bytecode), do: {:f64_lt, bytecode}
  defp parse_instruction(:f64_gt, bytecode), do: {:f64_gt, bytecode}
  defp parse_instruction(:f64_le, bytecode), do: {:f64_le, bytecode}
  defp parse_instruction(:f64_ge, bytecode), do: {:f64_ge, bytecode}
  defp parse_instruction(:f64_abs, bytecode), do: {:f64_abs, bytecode}
  defp parse_instruction(:f64_neg, bytecode), do: {:f64_neg, bytecode}
  defp parse_instruction(:f64_ceil, bytecode), do: {:f64_ceil, bytecode}
  defp parse_instruction(:f64_floor, bytecode), do: {:f64_floor, bytecode}
  defp parse_instruction(:f64_trunc, bytecode), do: {:f64_trunc, bytecode}
  defp parse_instruction(:f64_nearest, bytecode), do: {:f64_nearest, bytecode}

  defp parse_instruction(:f64_copysign, bytecode), do: {:f64_copysign, bytecode}
  defp parse_instruction(:i32_wrap_i64, bytecode), do: {:i32_wrap_i64, bytecode}
  defp parse_instruction(:i32_trunc_s_f32, bytecode), do: {:i32_trunc_s_f32, bytecode}
  defp parse_instruction(:i32_trunc_u_f32, bytecode), do: {:i32_trunc_u_f32, bytecode}
  defp parse_instruction(:i32_trunc_s_f64, bytecode), do: {:i32_trunc_s_f64, bytecode}
  defp parse_instruction(:i32_trunc_u_f64, bytecode), do: {:i32_trunc_u_f64, bytecode}
  defp parse_instruction(:i64_extend_s_i32, bytecode), do: {:i64_extend_s_i32, bytecode}
  defp parse_instruction(:i64_extend_u_i32, bytecode), do: {:i64_extend_u_i32, bytecode}
  defp parse_instruction(:i64_trunc_s_f32, bytecode), do: {:i64_trunc_s_f32, bytecode}
  defp parse_instruction(:i64_trunc_u_f32, bytecode), do: {:i64_trunc_u_f32, bytecode}
  defp parse_instruction(:i64_trunc_s_f64, bytecode), do: {:i64_trunc_s_f64, bytecode}
  defp parse_instruction(:i64_trunc_u_f64, bytecode), do: {:i64_trunc_u_f64, bytecode}
  defp parse_instruction(:f32_convert_s_i32, bytecode), do: {:f32_convert_s_i32, bytecode}
  defp parse_instruction(:f32_convert_u_i32, bytecode), do: {:f32_convert_u_i32, bytecode}
  defp parse_instruction(:f32_convert_s_i64, bytecode), do: {:f32_convert_s_i64, bytecode}
  defp parse_instruction(:f32_convert_u_i64, bytecode), do: {:f32_convert_u_i64, bytecode}
  defp parse_instruction(:f32_demote_f64, bytecode), do: {:f32_demote_f64, bytecode}
  defp parse_instruction(:f64_convert_s_i32, bytecode), do: {:f64_convert_s_i32, bytecode}
  defp parse_instruction(:f64_convert_u_i32, bytecode), do: {:f64_convert_u_i32, bytecode}
  defp parse_instruction(:f64_convert_s_i64, bytecode), do: {:f64_convert_s_i64, bytecode}
  defp parse_instruction(:f64_convert_u_i64, bytecode), do: {:f64_convert_u_i64, bytecode}
  defp parse_instruction(:f64_promote_f32, bytecode), do: {:f64_promote_f32, bytecode}
  defp parse_instruction(:i32_reinterpret_f32, bytecode), do: {:i32_reinterpret_f32, bytecode}
  defp parse_instruction(:i64_reinterpret_f64, bytecode), do: {:i64_reinterpret_f64, bytecode}
  defp parse_instruction(:f32_reinterpret_i32, bytecode), do: {:f32_reinterpret_i32, bytecode}
  defp parse_instruction(:f64_reinterpret_i64, bytecode), do: {:f64_reinterpret_i64, bytecode}
  defp parse_instruction(:drop, bytecode), do: {:drop, bytecode}
  defp parse_instruction(:select, bytecode), do: {:select, bytecode}
  defp parse_instruction(:return, bytecode), do: {:return, bytecode}
  defp parse_instruction(:memory_size, bytecode), do: {:memory_size, bytecode}
  defp parse_instruction(:memory_grow, bytecode), do: {:memory_grow, bytecode}


  #################### COMPLETED WITH NOTES ###############################

  defp parse_instruction(:f64_sqrt, bytecode), do: {:f64_sqrt, bytecode} # Done
  defp parse_instruction(:f64_add, bytecode), do: {:f64_add, bytecode} # Done
  defp parse_instruction(:f64_sub, bytecode), do: {:f64_sub, bytecode} # Done
  defp parse_instruction(:f64_mul, bytecode), do: {:f64_mul, bytecode} # Done
  defp parse_instruction(:f64_div, bytecode), do: {:f64_div, bytecode} # Done
  defp parse_instruction(:f64_min, bytecode), do: {:f64_min, bytecode} # Done
  defp parse_instruction(:f64_max, bytecode), do: {:f64_max, bytecode} # Done
  defp parse_instruction(:f32_sqrt, bytecode), do: {:f32_sqrt, bytecode} # Done
  defp parse_instruction(:f32_min, bytecode), do: {:f32_min, bytecode} # Done
  defp parse_instruction(:f32_max, bytecode), do: {:f32_max, bytecode} # Done
  defp parse_instruction(:f32_div, bytecode), do: {:f32_div, bytecode} # Done
  defp parse_instruction(:f32_add, bytecode), do: {:f32_add, bytecode} # Done
  defp parse_instruction(:f32_sub, bytecode), do: {:f32_sub, bytecode} # Done
  defp parse_instruction(:f32_mul, bytecode), do: {:f32_mul, bytecode} # Done
  defp parse_instruction(:i64_rem_s, bytecode), do: {:i64_rem_s, bytecode} # Done NEEDS FIXING
  defp parse_instruction(:i64_rem_u, bytecode), do: {:i64_rem_u, bytecode} # Done NEEDS FIXING
  defp parse_instruction(:i64_div_s, bytecode), do: {:i64_div_s, bytecode} # Done
  defp parse_instruction(:i64_div_u, bytecode), do: {:i64_div_u, bytecode} # Done
  defp parse_instruction(:i64_popcnt, bytecode), do: {:i64_popcnt, bytecode} # Done
  defp parse_instruction(:set_global, bytecode), do: get_single_value(:set_global, bytecode) # Done
  defp parse_instruction(:get_global, bytecode), do: get_single_value(:get_global, bytecode) # Done
  defp parse_instruction(:i64_shr_u, bytecode), do: {:i64_shr_u, bytecode} # Done
  defp parse_instruction(:get_local, bytecode), do: get_single_value(:get_local, bytecode) # Done
  defp parse_instruction(:set_local, bytecode), do: get_single_value(:set_local, bytecode) # Done
  defp parse_instruction(:tee_local, bytecode), do: get_single_value(:tee_local, bytecode) # Done
  defp parse_instruction(:i32_const, bytecode), do: get_single_value(:i32_const, bytecode) # Done
  defp parse_instruction(:i64_const, bytecode), do: get_single_value(:i64_const, bytecode) # Done
  defp parse_instruction(:f32_const, bytecode), do: get_single_value(:f32_const, bytecode) # Done
  defp parse_instruction(:f64_const, bytecode), do: get_single_value(:f64_const, bytecode) # Done
  defp parse_instruction(:i32_store, bytecode), do: get_two_values(:i32_store, bytecode) # Done
  defp parse_instruction(:i32_load, bytecode), do: get_two_values(:i32_load, bytecode) # Done
  defp parse_instruction(:i64_load, bytecode), do: get_two_values(:i64_load, bytecode) # Done
  defp parse_instruction(:f32_load, bytecode), do: get_two_values(:f32_load, bytecode) # Done
  defp parse_instruction(:f64_load, bytecode), do: get_two_values(:f64_load, bytecode) # Done
  defp parse_instruction(:i64_store, bytecode), do: get_two_values(:i64_store, bytecode) # Done
  defp parse_instruction(:f32_store, bytecode), do: get_two_values(:f32_store, bytecode) # Done
  defp parse_instruction(:f64_store, bytecode), do: get_two_values(:f64_store, bytecode) # Done
  defp parse_instruction(:i32_eqz, bytecode), do: {:i32_eqz, bytecode} # Done
  defp parse_instruction(:i32_eq, bytecode), do: {:i32_eq, bytecode} # Done
  defp parse_instruction(:i32_ne, bytecode), do: {:i32_ne, bytecode} # Done
  defp parse_instruction(:i32_lt_s, bytecode), do: {:i32_lt_s, bytecode} # Done
  defp parse_instruction(:i32_gt_s, bytecode), do: {:i32_gt_s, bytecode} # Done
  defp parse_instruction(:i32_le_s, bytecode), do: {:i32_le_s, bytecode} # Done
  defp parse_instruction(:i32_ge_s, bytecode), do: {:i32_ge_s, bytecode} # Done
  defp parse_instruction(:i32_clz, bytecode), do: {:i32_clz, bytecode} #NEED CLARIFICATION ON L/T Zeros
  defp parse_instruction(:i32_ctz, bytecode), do: {:i32_ctz, bytecode} #NEED CLARIFICATION ON L/T Zeros
  defp parse_instruction(:i32_popcnt, bytecode), do: {:i32_popcnt, bytecode} # Done
  defp parse_instruction(:i32_add, bytecode), do: {:i32_add, bytecode} # Done
  defp parse_instruction(:i32_sub, bytecode), do: {:i32_sub, bytecode} # Done
  defp parse_instruction(:i32_mul, bytecode), do: {:i32_mul, bytecode} # Done
  defp parse_instruction(:i32_div_s, bytecode), do: {:i32_div_, bytecode} # Done
  defp parse_instruction(:i32_div_u, bytecode), do: {:i32_div_, bytecode} # Done
  defp parse_instruction(:i32_rem_s, bytecode), do: {:i32_rem_, bytecode} # Done
  defp parse_instruction(:i32_rem_u, bytecode), do: {:i32_rem_, bytecode} # Done
  defp parse_instruction(:i32_or, bytecode), do: {:i32_or, bytecode} # Done
  defp parse_instruction(:i32_xor, bytecode), do: {:i32_xor, bytecode} # Done
  defp parse_instruction(:i32_shr_s, bytecode), do: {:i32_shr_, bytecode} # Done
  defp parse_instruction(:i64_eqz, bytecode), do: {:i64_eqz, bytecode} # Done
  defp parse_instruction(:i64_eq, bytecode), do: {:i64_eq, bytecode} # Done
  defp parse_instruction(:i64_ne, bytecode), do: {:i64_ne, bytecode} # Done
  defp parse_instruction(:i64_lt_s, bytecode), do: {:i64_lt_s, bytecode} # Done
  defp parse_instruction(:i64_gt_s, bytecode), do: {:i64_gt_s, bytecode} # Done
  defp parse_instruction(:i64_le_s, bytecode), do: {:i64_le_s, bytecode} # Done
  defp parse_instruction(:i64_ge_s, bytecode), do: {:i64_ge_s, bytecode} # Done
  defp parse_instruction(:i64_add, bytecode), do: {:i64_add, bytecode} # Done
  defp parse_instruction(:i64_sub, bytecode), do: {:i64_sub, bytecode} # Done
  defp parse_instruction(:i64_mul, bytecode), do: {:i64_mul, bytecode} # Done
  defp parse_instruction(:i64_or, bytecode), do: {:i64_or, bytecode} # Done
  defp parse_instruction(:i64_xor, bytecode), do: {:i64_xor, bytecode} # Done
  defp parse_instruction(:i64_shr_s, bytecode), do: {:i64_shr_s, bytecode} # Done
  defp parse_instruction(:unreachable, bytecode), do: {:unreachable, bytecode} # Done
  defp parse_instruction(:end, bytecode), do: {:end, bytecode} # Done
  defp parse_instruction(:nop, bytecode), do: {:nop, bytecode} # Done
  defp parse_instruction(no_match, _bytecode), do: raise "Couldn't parse instruction for #{no_match}"

  defp parse_block_type_instruction(opcode, bytecode) do
    {result_type, rest} = LEB128.decode(bytecode)

    if result_type == 0x40 do
      {{opcode, :no_res}, rest}
    else
      {opcode, rest} = LEB128.decode(rest)

      value_type = OpCodes.opcode_to_type(opcode)

      {{opcode, value_type}, rest}
    end
  end

  defp get_single_value(opcode, bytecode) do
    {val, rest} = LEB128.decode(bytecode)

    {{opcode, val}, rest}
  end

  defp get_two_values(opcode, bytecode) do
    {val1, rest} = LEB128.decode(bytecode)
    {val2, rest} = LEB128.decode(rest)

    {{opcode, val1, val2}, rest}
  end

  defp get_entries(bin, count), do: get_entries([], bin, count)
  defp get_entries(entries, bin, 0), do: {entries, bin}
  defp get_entries(entries, bin, count) do
    {entry, bin} = LEB128.decode(bin)

    get_entries([entry | entries], bin, count - 1)
  end

end
