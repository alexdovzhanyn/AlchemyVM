defmodule WaspVM.Gas do
  @cycle_cost 0.3125

  def cost(opcode), do: cpu_cycles(opcode) * @cycle_cost
  def cost(opcode, modifier), do: cpu_cycles(opcode, modifier) * @cycle_cost

  defp cpu_cycles(:i32_add), do: 1
  defp cpu_cycles(:i32_sub), do: 1
  defp cpu_cycles(:i32_mul), do: 5
  defp cpu_cycles(:i32_div_s), do: 20
  defp cpu_cycles(:i32_div_u), do: 20
  defp cpu_cycles(:i32_le_s), do: 1
  defp cpu_cycles(:i32_ge_s), do: 1
  defp cpu_cycles(:i32_lt_u), do: 1
  defp cpu_cycles(:i32_gt_u), do: 1
  defp cpu_cycles(:i32_le_u), do: 1
  defp cpu_cycles(:i32_ge_u), do: 1
  defp cpu_cycles(:i32_lt_s), do: 1
  defp cpu_cycles(:i32_ge_s), do: 1
  defp cpu_cycles(:i32_gt_s), do: 1
  defp cpu_cycles(:i32_eq), do: 1
  defp cpu_cycles(:i32_ne), do: 1
  defp cpu_cycles(:i32_eqz), do: 1
  defp cpu_cycles(:i32_rotl), do: 1
  defp cpu_cycles(:i32_rotr), do: 1
  defp cpu_cycles(:i32_and), do: 1
  defp cpu_cycles(:i32_or), do: 1
  defp cpu_cycles(:i32_xor), do: 1
  defp cpu_cycles(:i32_shl), do: 1
  defp cpu_cycles(:i32_shr_u), do: 1
  defp cpu_cycles(:i32_shr_s), do: 1
  defp cpu_cycles(:i32_rem_s), do: 20
  defp cpu_cycles(:i32_rem_u), do: 20
  defp cpu_cycles(:i32_const), do: 4
  defp cpu_cycles(:i32_wrap_i64), do: not_implemented(:i32_wrap_i64)
  defp cpu_cycles(:i32_trunc_u_f32), do: not_implemented(:i32_trunc_u_f32)
  defp cpu_cycles(:i32_trunc_s_f32), do: not_implemented(:i32_trunc_s_f32)
  defp cpu_cycles(:i32_trunc_u_f64), do: not_implemented(:i32_trunc_u_f64)
  defp cpu_cycles(:i32_trunc_s_f64), do: not_implemented(:i32_trunc_s_f64)
  defp cpu_cycles(:i32_reinterpret_f32), do: not_implemented(:i32_reinterpret_f32)
  defp cpu_cycles(:i32_load), do: not_implemented(:i32_load)
  defp cpu_cycles(:i32_load8_s), do: not_implemented(:i32_load8_s)
  defp cpu_cycles(:i32_load8_u), do: not_implemented(:i32_load8_u)
  defp cpu_cycles(:i32_load16_s), do: not_implemented(:i32_load16_s)
  defp cpu_cycles(:i32_load16_u), do: not_implemented(:i32_load16_u)
  defp cpu_cycles(:i32_store), do: not_implemented(:i32_store)
  defp cpu_cycles(:i32_store8), do: not_implemented(:i32_store8)
  defp cpu_cycles(:i32_store16), do: not_implemented(:i32_store16)


  defp cpu_cycles(:i64_add), do: 1
  defp cpu_cycles(:i64_sub), do: 1
  defp cpu_cycles(:i64_mul), do: 3
  defp cpu_cycles(:i64_div_s), do: 85
  defp cpu_cycles(:i64_div_u), do: 80
  defp cpu_cycles(:i64_le_s), do: 1
  defp cpu_cycles(:i64_ge_s), do: 1
  defp cpu_cycles(:i64_lt_u), do: 1
  defp cpu_cycles(:i64_gt_u), do: 1
  defp cpu_cycles(:i64_le_u), do: 1
  defp cpu_cycles(:i64_ge_u), do: 1
  defp cpu_cycles(:i64_lt_s), do: 1
  defp cpu_cycles(:i64_ge_s), do: 1
  defp cpu_cycles(:i64_gt_s), do: 1
  defp cpu_cycles(:i64_eq), do: 1
  defp cpu_cycles(:i64_ne), do: 1
  defp cpu_cycles(:i64_eqz), do: 1
  defp cpu_cycles(:i64_rotl), do: 1
  defp cpu_cycles(:i64_rotr), do: 1
  defp cpu_cycles(:i64_and), do: 1
  defp cpu_cycles(:i64_or), do: 1
  defp cpu_cycles(:i64_xor), do: 1
  defp cpu_cycles(:i64_shl), do: 1
  defp cpu_cycles(:i64_shr_u), do: 1
  defp cpu_cycles(:i64_shr_s), do: 1
  defp cpu_cycles(:i64_rem_s), do: 85
  defp cpu_cycles(:i64_rem_u), do: 80
  defp cpu_cycles(:i64_const), do: 4
  defp cpu_cycles(:i64_trunc_u_f32), do: not_implemented(:i64_trunc_u_f32)
  defp cpu_cycles(:i64_trunc_s_f32), do: not_implemented(:i64_trunc_s_f32)
  defp cpu_cycles(:i64_trunc_u_f64), do: not_implemented(:i64_trunc_u_f64)
  defp cpu_cycles(:i64_trunc_s_f64), do: not_implemented(:i64_trunc_s_f64)
  defp cpu_cycles(:i64_extend_u_i32), do: not_implemented(:i64_extend_u_i32)
  defp cpu_cycles(:i64_extend_s_i32), do: not_implemented(:i64_extend_s_i32)
  defp cpu_cycles(:i64_reinterpret_f32), do: not_implemented(:i64_reinterpret_f32)
  defp cpu_cycles(:i64_reinterpret_f64), do: not_implemented(:i64_reinterpret_f64)
  defp cpu_cycles(:i64_load), do: not_implemented(:i64_load)
  defp cpu_cycles(:i64_load8_s), do: not_implemented(:i64_load8_s)
  defp cpu_cycles(:i64_load8_u), do: not_implemented(:i64_load8_u)
  defp cpu_cycles(:i64_load16_s), do: not_implemented(:i64_load16_s)
  defp cpu_cycles(:i64_load16_u), do: not_implemented(:i64_load16_u)
  defp cpu_cycles(:i64_load32_s), do: not_implemented(:i64_load32_s)
  defp cpu_cycles(:i64_load32_u), do: not_implemented(:i64_load32_u)
  defp cpu_cycles(:i64_store), do: not_implemented(:i64_store)
  defp cpu_cycles(:i64_store8), do: not_implemented(:i64_store8)
  defp cpu_cycles(:i64_store16), do: not_implemented(:i64_store16)
  defp cpu_cycles(:i64_store32), do: not_implemented(:i64_store32)




  defp cpu_cycles(:f32_add), do: 4
  defp cpu_cycles(:f32_sub), do: 4
  defp cpu_cycles(:f32_mul), do: 4
  defp cpu_cycles(:f32_div), do: 11
  defp cpu_cycles(:f32_le), do: 4
  defp cpu_cycles(:f32_ge), do: 4
  defp cpu_cycles(:f32_lt), do: 4
  defp cpu_cycles(:f32_gt), do: 4
  defp cpu_cycles(:f32_eq), do: 4
  defp cpu_cycles(:f32_ne), do: 4
  defp cpu_cycles(:f32_const), do: 1
  defp cpu_cycles(:f32_min), do: 4
  defp cpu_cycles(:f32_max), do: 4
  defp cpu_cycles(:f32_copysign), do: not_implemented(:f32_copysign)
  defp cpu_cycles(:f32_nearest), do: not_implemented(:f32_nearest)
  defp cpu_cycles(:f32_trunc), do: not_implemented(:f32_trunc)
  defp cpu_cycles(:f32_floor), do: not_implemented(:f32_floor)
  defp cpu_cycles(:f32_neg), do: 5
  defp cpu_cycles(:f32_abs), do: not_implemented(:f32_abs)
  defp cpu_cycles(:f32_sqrt), do: 13
  defp cpu_cycles(:f32_ceil), do: not_implemented(:f32_ceil)
  defp cpu_cycles(:f32_convert_s_i32), do: not_implemented(:f32_convert_s_i32)
  defp cpu_cycles(:f32_convert_u_i32), do: not_implemented(:f32_convert_u_i32)
  defp cpu_cycles(:f32_convert_s_i64), do: not_implemented(:f32_convert_s_i64)
  defp cpu_cycles(:f32_convert_u_i64), do: not_implemented(:f32_convert_u_i64)
  defp cpu_cycles(:f32_demote_f64), do: not_implemented(:f32_demote_f64)
  defp cpu_cycles(:f32_reinterpret_i32), do: not_implemented(:f32_reinterpret_i32)
  defp cpu_cycles(:f32_load), do: not_implemented(:f32_load)
  defp cpu_cycles(:f32_store), do: not_implemented(:f32_store)

  defp cpu_cycles(:f64_add), do: 4
  defp cpu_cycles(:f64_sub), do: 4
  defp cpu_cycles(:f64_mul), do: 3
  defp cpu_cycles(:f64_div), do: 14
  defp cpu_cycles(:f64_le), do: 4
  defp cpu_cycles(:f64_ge), do: 4
  defp cpu_cycles(:f64_lt), do: 4
  defp cpu_cycles(:f64_gt), do: 4
  defp cpu_cycles(:f64_eq), do: 4
  defp cpu_cycles(:f64_ne), do: 4
  defp cpu_cycles(:f64_const), do: 1
  defp cpu_cycles(:f64_min), do: 4
  defp cpu_cycles(:f64_max), do: 4
  defp cpu_cycles(:f64_copysign), do: not_implemented(:f64_copysign)
  defp cpu_cycles(:f64_nearest), do: not_implemented(:f64_nearest)
  defp cpu_cycles(:f64_trunc), do: not_implemented(:f64_trunc)
  defp cpu_cycles(:f64_floor), do: not_implemented(:f64_floor)
  defp cpu_cycles(:f64_neg), do: 4
  defp cpu_cycles(:f64_abs), do: not_implemented(:f64_abs)
  defp cpu_cycles(:f64_sqrt), do: 18
  defp cpu_cycles(:f64_ceil), do: not_implemented(:f64_ceil)
  defp cpu_cycles(:f64_convert_s_i32), do: not_implemented(:f64_convert_s_i32)
  defp cpu_cycles(:f64_convert_u_i32), do: not_implemented(:f64_convert_u_i32)
  defp cpu_cycles(:f64_convert_s_i64), do: not_implemented(:f64_convert_s_i64)
  defp cpu_cycles(:f64_convert_u_i64), do: not_implemented(:f64_convert_u_i64)
  defp cpu_cycles(:f64_promote_f32), do: not_implemented(:f64_promote_f32)
  defp cpu_cycles(:f64_load), do: not_implemented(:f64_load)
  defp cpu_cycles(:f64_store), do: not_implemented(:f64_store)

  defp cpu_cycles(:if), do: 1
  defp cpu_cycles(:select), do: 5
  defp cpu_cycles(:br), do: 8
  defp cpu_cycles(:br_if), do: 9
  defp cpu_cycles(:nop), do: 0
  defp cpu_cycles(:unreachable), do: 0
  defp cpu_cycles(:return), do: 0
  defp cpu_cycles(:else), do: 0
  defp cpu_cycles(:drop), do: 4
  defp cpu_cycles(:loop), do: 8
  defp cpu_cycles(:block), do: 8
  defp cpu_cycles(:current_memory), do: not_implemented(:current_memory)
  defp cpu_cycles(:get_local), do: not_implemented(:get_local)
  defp cpu_cycles(:get_global), do: not_implemented(:get_global)
  defp cpu_cycles(:call), do: not_implemented(:call)
  defp cpu_cycles(:set_local), do: not_implemented(:set_local)
  defp cpu_cycles(:set_global), do: not_implemented(:set_global)
  defp cpu_cycles(:tee_local), do: not_implemented(:tee_local)
  defp cpu_cycles(:grow_memory), do: not_implemented(:grow_memory)

  defp cpu_cycles(:i32_popcnt, num_ones), do: 32 + num_ones
  defp cpu_cycles(:i32_clz, num_zeros), do: num_zeros * 2
  defp cpu_cycles(:i32_ctz, num_zeros), do: num_zeros * 2

  defp cpu_cycles(:i64_popcnt, num_ones), do: 64 + num_ones
  defp cpu_cycles(:i64_clz, num_zeros), do: num_zeros * 2
  defp cpu_cycles(:i64_ctz, num_zeros), do: num_zeros * 2

  defp cpu_cycles(:end, true), do: 0
  defp cpu_cycles(:end, _), do: 8

  defp not_implemented(opcode) do
    IO.warn("Gas cost not implemented for #{opcode}. Defaulting to cost of 1 cycle.")
    1
  end
end
