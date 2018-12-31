defmodule WaspVM.Decoder.Util do
  alias WaspVM.LEB128

  @moduledoc false

  def decode_resizeable_limits(bin) do
    <<flags, rest::binary>> = bin
    {initial, rest} = LEB128.decode_unsigned(rest)

    if flags > 0 do
      {max, rest} = LEB128.decode_unsigned(rest)

      {%{initial: initial, max: max}, rest}
    else
      {%{initial: initial}, rest}
    end
  end

  # In the MVP, to keep things simple while still supporting the basic
  # needs of dynamic linking, initializer expressions are restricted to
  # the four constant operators and get_global, where the global index
  # must refer to an immutable import.
  def evaluate_init_expr(entries), do: evaluate_init_expr([], entries)
  def evaluate_init_expr(parsed, bytecode) do
    <<opcode::bytes-size(1), bytecode::binary>> = bytecode

    {instruction, bytecode} =
      opcode
      |> WaspVM.OpCodes.encode_instr()
      |> WaspVM.Decoder.InstructionParser.parse_instruction(bytecode)

    if instruction == :end do
      # Should only be one instruction in the MVP, no other combination is valid
      [{instr, val}] = parsed

      if instr == :get_global do
        {parsed, bytecode}
      else
        {val, bytecode}
      end
    else
      evaluate_init_expr([instruction | parsed], bytecode)
    end
  end

end
