defmodule WaspVM.Decoder.InstructionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  require IEx

  @moduledoc false

  # Needs revisiting
  def parse_instruction(:call_indirect, bytecode) do
    {type_index, rest} = LEB128.decode_unsigned(bytecode)

    {{:call, type_index}, rest}
  end

  def parse_instruction(:br_table, bytecode) do
    {target_count, rest} = LEB128.decode_unsigned(bytecode)
    {target_table, rest} = get_entries(rest, target_count)
    {default_target, rest} = LEB128.decode_unsigned(rest)

    {{:br_table, target_table, default_target}, rest}
  end

#################### NOT COMPLETED ###############################

  def parse_instruction(:i32_load8_s, bytecode), do: get_two_values(:i32_load8_s, bytecode)
  def parse_instruction(:i32_load8_u, bytecode), do: get_two_values(:i32_load8_u, bytecode)
  def parse_instruction(:i32_load16_u, bytecode), do: get_two_values(:i32_load16_u, bytecode)
  def parse_instruction(:i64_load8_s, bytecode), do: get_two_values(:i64_load8_s, bytecode)
  def parse_instruction(:i64_load8_u, bytecode), do: get_two_values(:i64_load8_u, bytecode)
  def parse_instruction(:i64_load16_s, bytecode), do: get_two_values(:i64_load16_s, bytecode)
  def parse_instruction(:i64_load16_u, bytecode), do: get_two_values(:i64_load16_u, bytecode)
  def parse_instruction(:i64_load32_s, bytecode), do: get_two_values(:i64_load32_s, bytecode)
  def parse_instruction(:i64_load32_u, bytecode), do: get_two_values(:i64_load32_u, bytecode)




  def parse_instruction(:i32_wrap_i64, bytecode), do: {:i32_wrap_i64, bytecode}
  def parse_instruction(:i32_trunc_s_f32, bytecode), do: {:i32_trunc_s_f32, bytecode}
  def parse_instruction(:i32_trunc_u_f32, bytecode), do: {:i32_trunc_u_f32, bytecode}
  def parse_instruction(:i32_trunc_s_f64, bytecode), do: {:i32_trunc_s_f64, bytecode}
  def parse_instruction(:i32_trunc_u_f64, bytecode), do: {:i32_trunc_u_f64, bytecode}
  def parse_instruction(:i64_extend_s_i32, bytecode), do: {:i64_extend_s_i32, bytecode}
  def parse_instruction(:i64_extend_u_i32, bytecode), do: {:i64_extend_u_i32, bytecode}
  def parse_instruction(:i64_trunc_s_f32, bytecode), do: {:i64_trunc_s_f32, bytecode}
  def parse_instruction(:i64_trunc_u_f32, bytecode), do: {:i64_trunc_u_f32, bytecode}
  def parse_instruction(:i64_trunc_s_f64, bytecode), do: {:i64_trunc_s_f64, bytecode}
  def parse_instruction(:i64_trunc_u_f64, bytecode), do: {:i64_trunc_u_f64, bytecode}
  def parse_instruction(:f32_convert_s_i32, bytecode), do: {:f32_convert_s_i32, bytecode}
  def parse_instruction(:f32_convert_u_i32, bytecode), do: {:f32_convert_u_i32, bytecode}
  def parse_instruction(:f32_convert_s_i64, bytecode), do: {:f32_convert_s_i64, bytecode}
  def parse_instruction(:f32_convert_u_i64, bytecode), do: {:f32_convert_u_i64, bytecode}
  def parse_instruction(:f32_demote_f64, bytecode), do: {:f32_demote_f64, bytecode}
  def parse_instruction(:f64_convert_s_i32, bytecode), do: {:f64_convert_s_i32, bytecode}
  def parse_instruction(:f64_convert_u_i32, bytecode), do: {:f64_convert_u_i32, bytecode}
  def parse_instruction(:f64_convert_s_i64, bytecode), do: {:f64_convert_s_i64, bytecode}
  def parse_instruction(:f64_convert_u_i64, bytecode), do: {:f64_convert_u_i64, bytecode}
  def parse_instruction(:f64_promote_f32, bytecode), do: {:f64_promote_f32, bytecode}
  def parse_instruction(:i32_reinterpret_f32, bytecode), do: {:i32_reinterpret_f32, bytecode}
  def parse_instruction(:i64_reinterpret_f64, bytecode), do: {:i64_reinterpret_f64, bytecode}
  def parse_instruction(:f32_reinterpret_i32, bytecode), do: {:f32_reinterpret_i32, bytecode}
  def parse_instruction(:f64_reinterpret_i64, bytecode), do: {:f64_reinterpret_i64, bytecode}


  def parse_instruction(:return, bytecode), do: {:return, bytecode}
  def parse_instruction(:memory_size, bytecode), do: {:memory_size, bytecode}
  def parse_instruction(:memory_grow, bytecode), do: {:memory_grow, bytecode}


  #################### COMPLETED WITH NOTES ###############################
  def parse_instruction(:i64_store32, bytecode), do: get_two_values(:i64_store32, bytecode) # Done
  def parse_instruction(:i64_store8, bytecode), do: get_two_values(:i64_store8, bytecode) # Done
  def parse_instruction(:i64_store16, bytecode), do: get_two_values(:i64_store16, bytecode)  # Done
  def parse_instruction(:i32_store16, bytecode), do: get_two_values(:i32_store16, bytecode) # Done
  def parse_instruction(:i32_store8, bytecode), do: get_two_values(:i32_store8, bytecode) # Done
  def parse_instruction(:if, bytecode), do: parse_block_type_instruction(:if, bytecode) # Done
  def parse_instruction(:else, bytecode), do: {:else, bytecode} # Done
  def parse_instruction(:block, bytecode), do: parse_block_type_instruction(:block, bytecode) # Done
  def parse_instruction(:loop, bytecode), do: parse_block_type_instruction(:loop, bytecode) # Done
  def parse_instruction(:br, bytecode), do: get_single_value(:br, bytecode) # Done
  def parse_instruction(:br_if, bytecode), do: get_single_value(:br_if, bytecode) # Done
  def parse_instruction(:call, bytecode), do: get_single_value(:call, bytecode) # Done
  def parse_instruction(:select, bytecode), do: {:select, bytecode} # Done
  def parse_instruction(:drop, bytecode), do: {:drop, bytecode} # Done
  def parse_instruction(:i64_clz, bytecode), do: {:i64_clz, bytecode} # Done
  def parse_instruction(:i64_ctz, bytecode), do: {:i64_ctz, bytecode} # Done
  def parse_instruction(:i32_clz, bytecode), do: {:i32_clz, bytecode} # Done
  def parse_instruction(:i32_ctz, bytecode), do: {:i32_ctz, bytecode} # Done
  def parse_instruction(:i32_ge_u, bytecode), do: {:i32_ge_u, bytecode} # Done
  def parse_instruction(:i64_ge_u, bytecode), do: {:i64_ge_u, bytecode} # Done
  def parse_instruction(:i32_le_u, bytecode), do: {:i32_le_u, bytecode} # Done
  def parse_instruction(:i64_le_u, bytecode), do: {:i64_le_u, bytecode} # Done
  def parse_instruction(:i32_gt_u, bytecode), do: {:i32_gt_u, bytecode} # Done
  def parse_instruction(:i64_gt_u, bytecode), do: {:i64_gt_u, bytecode} # Done
  def parse_instruction(:f32_copysign, bytecode), do: {:f32_copysign, bytecode} # Done
  def parse_instruction(:f64_copysign, bytecode), do: {:f64_copysign, bytecode} # Done
  def parse_instruction(:i32_lt_u, bytecode), do: {:i32_lt_u, bytecode} # Done
  def parse_instruction(:i64_lt_u, bytecode), do: {:i64_lt_u, bytecode} # Done
  def parse_instruction(:i32_rotl, bytecode), do: {:i32_rotl, bytecode} # Done
  def parse_instruction(:i32_rotr, bytecode), do: {:i32_rotr, bytecode} # Done
  def parse_instruction(:i64_rotl, bytecode), do: {:i64_rotl, bytecode} # Done
  def parse_instruction(:i64_rotr, bytecode), do: {:i64_rotr, bytecode} # Done
  def parse_instruction(:i32_shl, bytecode), do: {:i32_shl, bytecode} # Done
  def parse_instruction(:i32_shr_u, bytecode), do: {:i32_shr_u, bytecode} # Done
  def parse_instruction(:i64_shl, bytecode), do: {:i64_shl, bytecode} # Done
  def parse_instruction(:f32_gt, bytecode), do: {:f32_gt, bytecode} # Done
  def parse_instruction(:f32_le, bytecode), do: {:f32_le, bytecode} # Done
  def parse_instruction(:f32_ge, bytecode), do: {:f32_ge, bytecode} # Done
  def parse_instruction(:f64_gt, bytecode), do: {:f64_gt, bytecode} # Done
  def parse_instruction(:f64_le, bytecode), do: {:f64_le, bytecode} # Done
  def parse_instruction(:f64_ge, bytecode), do: {:f64_ge, bytecode} # Done
  def parse_instruction(:f32_lt, bytecode), do: {:f32_lt, bytecode} # Done
  def parse_instruction(:f64_lt, bytecode), do: {:f64_lt, bytecode} # Done
  def parse_instruction(:f32_ne, bytecode), do: {:f32_ne, bytecode} # Done
  def parse_instruction(:f64_ne, bytecode), do: {:f64_ne, bytecode} # Done
  def parse_instruction(:f32_eq, bytecode), do: {:f32_eq, bytecode} # Done
  def parse_instruction(:f64_eq, bytecode), do: {:f64_eq, bytecode} # Done
  def parse_instruction(:f32_nearest, bytecode), do: {:f32_nearest, bytecode} # Done
  def parse_instruction(:f64_nearest, bytecode), do: {:f64_nearest, bytecode} # Done
  def parse_instruction(:f32_trunc, bytecode), do: {:f32_trunc, bytecode} # Done
  def parse_instruction(:f64_trunc, bytecode), do: {:f64_trunc, bytecode} # Done
  def parse_instruction(:f32_floor, bytecode), do: {:f32_floor, bytecode} # Done
  def parse_instruction(:f64_floor, bytecode), do: {:f64_floor, bytecode} # Done
  def parse_instruction(:f32_ceil, bytecode), do: {:f32_ceil, bytecode} # Done
  def parse_instruction(:f64_ceil, bytecode), do: {:f64_ceil, bytecode} # Done
  def parse_instruction(:f32_neg, bytecode), do: {:f32_neg, bytecode} # Done
  def parse_instruction(:f64_neg, bytecode), do: {:f64_neg, bytecode} # Done
  def parse_instruction(:f32_abs, bytecode), do: {:f32_abs, bytecode} # Done
  def parse_instruction(:f64_abs, bytecode), do: {:f64_abs, bytecode} # Done
  def parse_instruction(:f64_sqrt, bytecode), do: {:f64_sqrt, bytecode} # Done
  def parse_instruction(:f64_add, bytecode), do: {:f64_add, bytecode} # Done
  def parse_instruction(:f64_sub, bytecode), do: {:f64_sub, bytecode} # Done
  def parse_instruction(:f64_mul, bytecode), do: {:f64_mul, bytecode} # Done
  def parse_instruction(:f64_div, bytecode), do: {:f64_div, bytecode} # Done
  def parse_instruction(:f64_min, bytecode), do: {:f64_min, bytecode} # Done
  def parse_instruction(:f64_max, bytecode), do: {:f64_max, bytecode} # Done
  def parse_instruction(:f32_sqrt, bytecode), do: {:f32_sqrt, bytecode} # Done
  def parse_instruction(:f32_min, bytecode), do: {:f32_min, bytecode} # Done
  def parse_instruction(:f32_max, bytecode), do: {:f32_max, bytecode} # Done
  def parse_instruction(:f32_div, bytecode), do: {:f32_div, bytecode} # Done
  def parse_instruction(:f32_add, bytecode), do: {:f32_add, bytecode} # Done
  def parse_instruction(:f32_sub, bytecode), do: {:f32_sub, bytecode} # Done
  def parse_instruction(:f32_mul, bytecode), do: {:f32_mul, bytecode} # Done
  def parse_instruction(:i64_rem_s, bytecode), do: {:i64_rem_s, bytecode} # Done NEEDS FIXING
  def parse_instruction(:i64_rem_u, bytecode), do: {:i64_rem_u, bytecode} # Done NEEDS FIXING
  def parse_instruction(:i64_div_s, bytecode), do: {:i64_div_s, bytecode} # Done
  def parse_instruction(:i64_div_u, bytecode), do: {:i64_div_u, bytecode} # Done
  def parse_instruction(:i64_popcnt, bytecode), do: {:i64_popcnt, bytecode} # Done
  def parse_instruction(:set_global, bytecode), do: get_single_value(:set_global, bytecode) # Done
  def parse_instruction(:get_global, bytecode), do: get_single_value(:get_global, bytecode) # Done
  def parse_instruction(:i64_shr_u, bytecode), do: {:i64_shr_u, bytecode} # Done
  def parse_instruction(:get_local, bytecode), do: get_single_value(:get_local, bytecode) # Done
  def parse_instruction(:set_local, bytecode), do: get_single_value(:set_local, bytecode) # Done
  def parse_instruction(:tee_local, bytecode), do: get_single_value(:tee_local, bytecode) # Done
  def parse_instruction(:i32_const, bytecode), do: get_single_value(:i32_const, bytecode) # Done
  def parse_instruction(:i64_const, bytecode), do: get_single_value(:i64_const, bytecode) # Done
  def parse_instruction(:f32_const, bytecode), do: get_single_float(:f32_const, bytecode) # Done
  def parse_instruction(:f64_const, bytecode), do: get_single_float(:f64_const, bytecode) # Done
  def parse_instruction(:i32_store, bytecode), do: get_two_values(:i32_store, bytecode) # Done
  def parse_instruction(:i32_load, bytecode), do: get_two_values(:i32_load, bytecode) # Done
  def parse_instruction(:i64_load, bytecode), do: get_two_values(:i64_load, bytecode) # Done
  def parse_instruction(:f32_load, bytecode), do: get_two_values(:f32_load, bytecode) # Done
  def parse_instruction(:f64_load, bytecode), do: get_two_values(:f64_load, bytecode) # Done
  def parse_instruction(:i64_store, bytecode), do: get_two_values(:i64_store, bytecode) # Done
  def parse_instruction(:f32_store, bytecode), do: get_two_values(:f32_store, bytecode) # Done
  def parse_instruction(:f64_store, bytecode), do: get_two_values(:f64_store, bytecode) # Done
  def parse_instruction(:i32_eqz, bytecode), do: {:i32_eqz, bytecode} # Done
  def parse_instruction(:i32_eq, bytecode), do: {:i32_eq, bytecode} # Done
  def parse_instruction(:i32_ne, bytecode), do: {:i32_ne, bytecode} # Done
  def parse_instruction(:i32_lt_s, bytecode), do: {:i32_lt_s, bytecode} # Done
  def parse_instruction(:i32_gt_s, bytecode), do: {:i32_gt_s, bytecode} # Done
  def parse_instruction(:i32_le_s, bytecode), do: {:i32_le_s, bytecode} # Done
  def parse_instruction(:i32_ge_s, bytecode), do: {:i32_ge_s, bytecode} # Done
  def parse_instruction(:i32_clz, bytecode), do: {:i32_clz, bytecode} #NEED CLARIFICATION ON L/T Zeros
  def parse_instruction(:i32_ctz, bytecode), do: {:i32_ctz, bytecode} #NEED CLARIFICATION ON L/T Zeros
  def parse_instruction(:i32_popcnt, bytecode), do: {:i32_popcnt, bytecode} # Done
  def parse_instruction(:i32_add, bytecode), do: {:i32_add, bytecode} # Done
  def parse_instruction(:i32_sub, bytecode), do: {:i32_sub, bytecode} # Done
  def parse_instruction(:i32_mul, bytecode), do: {:i32_mul, bytecode} # Done
  def parse_instruction(:i32_div_s, bytecode), do: {:i32_div_s, bytecode} # Done
  def parse_instruction(:i32_div_u, bytecode), do: {:i32_div_u, bytecode} # Done
  def parse_instruction(:i32_rem_s, bytecode), do: {:i32_rem_s, bytecode} # Done
  def parse_instruction(:i32_rem_u, bytecode), do: {:i32_rem_u, bytecode} # Done
  def parse_instruction(:i32_or, bytecode), do: {:i32_or, bytecode} # Done
  def parse_instruction(:i32_and, bytecode), do: {:i32_and, bytecode} # Done
  def parse_instruction(:i64_and, bytecode), do: {:i64_and, bytecode} # Done
  def parse_instruction(:i32_xor, bytecode), do: {:i32_xor, bytecode} # Done
  def parse_instruction(:i32_shr_s, bytecode), do: {:i32_shr_s, bytecode} # Done
  def parse_instruction(:i64_eqz, bytecode), do: {:i64_eqz, bytecode} # Done
  def parse_instruction(:i64_eq, bytecode), do: {:i64_eq, bytecode} # Done
  def parse_instruction(:i64_ne, bytecode), do: {:i64_ne, bytecode} # Done
  def parse_instruction(:i64_lt_s, bytecode), do: {:i64_lt_s, bytecode} # Done
  def parse_instruction(:i64_gt_s, bytecode), do: {:i64_gt_s, bytecode} # Done
  def parse_instruction(:i64_le_s, bytecode), do: {:i64_le_s, bytecode} # Done
  def parse_instruction(:i64_ge_s, bytecode), do: {:i64_ge_s, bytecode} # Done
  def parse_instruction(:i64_add, bytecode), do: {:i64_add, bytecode} # Done
  def parse_instruction(:i64_sub, bytecode), do: {:i64_sub, bytecode} # Done
  def parse_instruction(:i64_mul, bytecode), do: {:i64_mul, bytecode} # Done
  def parse_instruction(:i64_or, bytecode), do: {:i64_or, bytecode} # Done
  def parse_instruction(:i64_xor, bytecode), do: {:i64_xor, bytecode} # Done
  def parse_instruction(:i64_shr_s, bytecode), do: {:i64_shr_s, bytecode} # Done
  def parse_instruction(:unreachable, bytecode), do: {:unreachable, bytecode} # Done
  def parse_instruction(:end, bytecode), do: {:end, bytecode} # Done
  def parse_instruction(:nop, bytecode), do: {:nop, bytecode} # Done
  def parse_instruction(no_match, _bytecode), do: raise "Couldn't parse instruction for #{no_match}"

  defp parse_block_type_instruction(opcode, bytecode) do
    {result_type, rest} = LEB128.decode_unsigned(bytecode)
    if result_type == 0x40 do
      {{opcode, :no_res}, rest}
    else
      value_type = OpCodes.opcode_to_type(<<result_type>>)

      {{opcode, value_type}, rest}
    end
  end

  defp get_single_value(opcode, bytecode) do
    {val, rest} = LEB128.decode_signed(bytecode)

    {{opcode, val}, rest}
  end

  defp get_single_float(:f32_const = opcode, bytecode) do
    <<little_endian::bytes-size(4), rest::binary>> = bytecode

    <<val::32-float>> = little_to_big(little_endian)

    {{opcode, val}, rest}
  end

  defp get_single_float(:f64_const = opcode, bytecode) do
    <<little_endian::bytes-size(8), rest::binary>> = bytecode

    <<val::64-float>> = little_to_big(little_endian)

    {{opcode, val}, rest}
  end

  defp get_two_values(opcode, bytecode) do
    {val1, rest} = LEB128.decode_signed(bytecode)
    {val2, rest} = LEB128.decode_signed(rest)

    {{opcode, val1, val2}, rest}
  end

  defp get_entries(bin, count), do: get_entries([], bin, count)
  defp get_entries(entries, bin, 0), do: {entries, bin}
  defp get_entries(entries, bin, count) do
    {entry, bin} = LEB128.decode_unsigned(bin)

    get_entries([entry | entries], bin, count - 1)
  end

  defp little_to_big(bin) do
    bin
    |> :binary.decode_unsigned(:little)
    |> :binary.encode_unsigned(:big)
  end
end
