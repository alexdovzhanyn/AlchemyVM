defmodule WaspVM.Decoder.GlobalSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Module
  alias WaspVM.Decoder.InstructionParser
  require IEx

  @moduledoc false

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(6)
      |> LEB128.decode_unsigned()

    globals = if count > 0, do: Enum.reverse(parse_entries(entries)), else: []

    Map.put(module, :globals, globals)
  end

  defp parse_entries(entries), do: parse_entries([], entries)
  defp parse_entries(parsed, <<>>), do: parsed

  defp parse_entries(parsed, entries) do
    {opcode, entries} = LEB128.decode_unsigned(entries)

    type = OpCodes.opcode_to_type(<<opcode>>)

    {mutability, entries} = LEB128.decode_unsigned(entries)

    mutable = mutability == 1

    {initial, entries} = evaluate_init_expr(entries)

    global = %{type: type, mutable: mutable, initial: initial}

    parse_entries([global | parsed], entries)
  end

  # In the MVP, to keep things simple while still supporting the basic
  # needs of dynamic linking, initializer expressions are restricted to
  # the four constant operators and get_global, where the global index
  # must refer to an immutable import.
  defp evaluate_init_expr(entries), do: evaluate_init_expr([], entries)
  defp evaluate_init_expr(parsed, bytecode) do
    <<opcode::bytes-size(1), bytecode::binary>> = bytecode

    {instruction, bytecode} =
      opcode
      |> OpCodes.encode_instr()
      |> InstructionParser.parse_instruction(bytecode)

    if instruction == :end do
      # Should only be one instruction in the MVP, no other combination is valid
      [{instr, val}] = parsed

      if instr == :get_global do
        raise "Not implemented: :get_global in init expression"
      else
        {val, bytecode}
      end
    else
      evaluate_init_expr([instruction | parsed], bytecode)
    end
  end


end
