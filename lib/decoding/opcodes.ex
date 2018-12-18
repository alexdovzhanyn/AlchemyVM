defmodule WaspVM.OpCodes do
  require IEx

  @doc """
    Returns an atom representing a given language opcode
  """
  def encode_instr(instr) do
    case instr do
      # Control instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#control-instructions)
      <<0x00>> -> :unreachable
      <<0x01>> -> :nop
      <<0x02>> -> :block
      <<0x03>> -> :loop
      <<0x04>> -> :if
      <<0x0C>> -> :br
      <<0x0D>> -> :br_if
      <<0x0E>> -> :br_table
      <<0x0F>> -> :return
      <<0x10>> -> :call
      <<0x11>> -> :call_indirect
      <<0x0B>> -> :end

      # Parameteric instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#parametric-instructions)
      <<0x1A>> -> :drop
      <<0x1B>> -> :select

      # Variable instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#variable-instructions)
      # Takes the second byte as the argument
      <<0x20>> -> :get_local
      <<0x21>> -> :set_local
      <<0x22>> -> :tee_local
      <<0x23>> -> :get_global
      <<0x24>> -> :set_global

      # Memory instructions. [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#memory-instructions)
      #loads & Stores by imemdaite arg
      <<0x28>> -> :i32_load
      <<0x29>> -> :i64_load
      <<0x2A>> -> :f32_load
      <<0x2B>> -> :f64_load
      <<0x2C>> -> :i32_load8_s
      <<0x2D>> -> :i32_load8_u
      <<0x2E>> -> :i32_load16_s
      <<0x2F>> -> :i32_load16_u
      <<0x30>> -> :i64_load8_s
      <<0x31>> -> :i64_load8_u
      <<0x32>> -> :i64_load16_s
      <<0x33>> -> :i64_load16_u
      <<0x34>> -> :i64_load32_s
      <<0x35>> -> :i64_load32_u
      <<0x36>> -> :i32_store
      <<0x37>> -> :i64_store
      <<0x38>> -> :f32_store
      <<0x39>> -> :f64_store
      <<0x3A>> -> :i32_store8
      <<0x3B>> -> :i32_store16
      <<0x3C>> -> :i64_store8
      <<0x3D>> -> :i64_store16
      <<0x3E>> -> :i64_store32
      <<0x3F>> -> :current_memory
      <<0x40>> -> :grow_memory

      # Numberic instructions . [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#numeric-instructions)
      # Constant followed by immedaite arg
      <<0x41>> -> :i32_const
      <<0x42>> -> :i64_const
      <<0x43>> -> :f32_const
      <<0x44>> -> :f64_const

      # Numberic instructions . [Spec reference.](http://webassembly.github.io/spec/core/bikeshed/index.html#numeric-instructions)
      <<0x45>> -> :i32_eqz
      <<0x46>> -> :i32_eq
      <<0x47>> -> :i32_ne
      <<0x48>> -> :i32_lt_s
      <<0x49>> -> :i32_lt_u
      <<0x4A>> -> :i32_gt_s
      <<0x4B>> -> :i32_gt_u
      <<0x4C>> -> :i32_le_s
      <<0x4D>> -> :i32_le_u
      <<0x4E>> -> :i32_ge_s
      <<0x4F>> -> :i32_ge_u
      <<0x67>> -> :i32_clz
      <<0x68>> -> :i32_ctz
      <<0x69>> -> :i32_popcnt
      <<0x6A>> -> :i32_add
      <<0x6B>> -> :i32_sub
      <<0x6C>> -> :i32_mul
      <<0x6D>> -> :i32_div_s
      <<0x6E>> -> :i32_div_u
      <<0x6F>> -> :i32_rem_s
      <<0x70>> -> :i32_rem_u
      <<0x71>> -> :i32_add
      <<0x72>> -> :i32_or
      <<0x73>> -> :i32_xor
      <<0x74>> -> :i32_shl
      <<0x75>> -> :i32_shr_s
      <<0x76>> -> :i32_shr_u
      <<0x77>> -> :i32_rotl
      <<0x78>> -> :i32_rotr
      <<0x50>> -> :i64_eqz
      <<0x51>> -> :i64_eq
      <<0x52>> -> :i64_ne
      <<0x53>> -> :i64_lt_s
      <<0x54>> -> :i64_lt_u
      <<0x55>> -> :i64_gt_s
      <<0x56>> -> :i64_gt_u
      <<0x57>> -> :i64_le_s
      <<0x58>> -> :i64_le_u
      <<0x59>> -> :i64_ge_s
      <<0x5A>> -> :i64_ge_u
      <<0x79>> -> :i64_clz
      <<0x7A>> -> :i64_ctz
      <<0x7B>> -> :i64_popcnt
      <<0x7C>> -> :i64_add
      <<0x7D>> -> :i64_sub
      <<0x7E>> -> :i64_mul
      <<0x7F>> -> :i64_div_s
      <<0x80>> -> :i64_div_u
      <<0x81>> -> :i64_rem_s
      <<0x82>> -> :i64_rem_u
      <<0x83>> -> :i64_add
      <<0x84>> -> :i64_or
      <<0x85>> -> :i64_xor
      <<0x86>> -> :i64_shl
      <<0x87>> -> :i64_shr_s
      <<0x88>> -> :i64_shr_u
      <<0x89>> -> :i64_rotl
      <<0x8A>> -> :i64_rotr
      <<0x5B>> -> :f32_eq
      <<0x5C>> -> :f32_ne
      <<0x5D>> -> :f32_lt
      <<0x5E>> -> :f32_gt
      <<0x5F>> -> :f32_le
      <<0x60>> -> :f32_ge
      <<0x8B>> -> :f32_abs
      <<0x8C>> -> :f32_neg
      <<0x8D>> -> :f32_ceil
      <<0x8E>> -> :f32_floor
      <<0x8F>> -> :f32_trunc
      <<0x90>> -> :f32_nearest
      <<0x91>> -> :f32_sqrt
      <<0x92>> -> :f32_add
      <<0x93>> -> :f32_sub
      <<0x94>> -> :f32_mul
      <<0x95>> -> :f32_div
      <<0x96>> -> :f32_min
      <<0x97>> -> :f32_max
      <<0x98>> -> :f32_copysign
      <<0x61>> -> :f64_eq
      <<0x62>> -> :f64_ne
      <<0x63>> -> :f64_lt
      <<0x64>> -> :f64_gt
      <<0x65>> -> :f64_le
      <<0x66>> -> :f64_ge
      <<0x99>> -> :f64_abs
      <<0x9A>> -> :f64_neg
      <<0x9B>> -> :f64_ceil
      <<0x9C>> -> :f64_floor
      <<0x9D>> -> :f64_trunc
      <<0x9E>> -> :f64_nearest
      <<0x9F>> -> :f64_sqrt
      <<0xA0>> -> :f64_add
      <<0xA1>> -> :f64_sub
      <<0xA2>> -> :f64_mul
      <<0xA3>> -> :f64_div
      <<0xA4>> -> :f64_min
      <<0xA5>> -> :f64_max
      <<0xA6>> -> :f64_copysign
      <<0xA7>> -> :i32_wrap_i64
      <<0xA8>> -> :i32_trunc_s_f32
      <<0xA9>> -> :i32_trunc_u_f32
      <<0xAA>> -> :i32_trunc_s_f64
      <<0xAB>> -> :i32_trunc_u_f64
      <<0xAC>> -> :i64_extend_s_i32
      <<0xAD>> -> :i64_extend_u_i32
      <<0xAE>> -> :i64_trunc_s_f32
      <<0xAF>> -> :i64_trunc_u_f32
      <<0xB0>> -> :i64_trunc_s_f64
      <<0xB1>> -> :i64_trunc_u_f64
      <<0xB2>> -> :f32_convert_s_i32
      <<0xB3>> -> :f32_convert_u_i32
      <<0xB4>> -> :f32_convert_s_i64
      <<0xB5>> -> :f32_convert_u_i64
      <<0xB6>> -> :f32_demote_f64
      <<0xB7>> -> :f64_convert_s_i32
      <<0xB8>> -> :f64_convert_u_i32
      <<0xB9>> -> :f64_convert_s_i64
      <<0xBA>> -> :f64_convert_u_i64
      <<0xBB>> -> :f64_promote_f32
      <<0xBC>> -> :i32_reinterpret_f32
      <<0xBD>> -> :i64_reinterpret_f64
      <<0xBE>> -> :f32_reinterpret_i32
      <<0xBF>> -> :f64_reinterpret_i64
      any ->
        IEx.pry

    end
  end

  @doc """
    Returns an atom representing a language type based on a given opcode
  """
  def opcode_to_type(opcode) do
    case opcode do
      <<0x7F>> -> :i32
      <<0x7E>> -> :i64
      <<0x7D>> -> :f32
      <<0x7C>> -> :f64
      <<0x70>> -> :anyfunc
      <<0x60>> -> :func
      <<0x40>> -> :empty_block
    end
  end

  def type_to_opcode(type) do
    case type do
      :i32 -> <<0x7F>>
      :i64 -> <<0x7E>>
      :f32 -> <<0x7D>>
      :f64 -> <<0x7C>>
      :anyfunc -> <<0x70>>
      :func -> <<0x60>>
      :empty_block -> <<0x40>>
    end
  end

  def external_kind(kind) do
    case kind do
      0 -> :func
      1 -> :table
      2 -> :mem
      3 -> :global
    end
  end

end
