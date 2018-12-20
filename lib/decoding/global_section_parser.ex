defmodule WaspVM.Decoder.GlobalSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Module
  alias WaspVM.Decoder.InstructionParser
  require IEx

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(6)
      |> LEB128.decode_unsigned()

    IO.inspect(count, label: "GLOBAL COUNT")

    globals = if count > 0, do: parse_entries(entries), else: []

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

    IEx.pry
  end

  defp evaluate_init_expr(entries), do: evaluate_init_expr([], entries)
  defp evaluate_init_expr(parsed, bytecode) do
    <<opcode::bytes-size(1), bytecode::binary>> = bytecode

    {instruction, bytecode} =
      opcode
      |> OpCodes.encode_instr()
      |> InstructionParser.parse_instruction(bytecode)

    if instruction == :end do
      execute_init_expr({parsed, bytecode})
    else
      evaluate_init_expr([instruction | parsed], bytecode)
    end
  end

  defp execute_init_expr({expr, bytecode}) do
    IEx.pry
    #
    #
    # {, bytecode}
  end

end
