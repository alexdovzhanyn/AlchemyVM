defmodule WaspVM.Decoder.CodeSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Decoder.InstructionParser
  require IEx

  def parse(module) do
    {count, bodies} =
      module.sections
      |> Map.get(10)
      |> LEB128.decode_unsigned()

    bodies = if count > 0, do: parse_bodies(bodies), else: []

    Map.put(module, :functions, Enum.reverse(bodies))
  end

  defp parse_bodies(bodies), do: parse_bodies([], bodies)
  defp parse_bodies(parsed, <<>>), do: parsed

  defp parse_bodies(parsed, bodies) do
    {body_size, bodies} = LEB128.decode_unsigned(bodies)

    <<body::bytes-size(body_size), bodies::binary>> = bodies

    {local_count, body} = LEB128.decode_unsigned(body)

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
    {ct, bin} = LEB128.decode_unsigned(bin)

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
      |> InstructionParser.parse_instruction(bytecode)

    parse_bytecode([instruction | instructions], bytecode)
  end
end
