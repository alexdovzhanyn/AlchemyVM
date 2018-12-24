defmodule WaspVM.Decoder.CodeSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Decoder.InstructionParser
  require IEx

  @moduledoc false

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
      |> find_block_pairs()

    body = %{locals: locals, body: parsed_bytecode}

    parse_bodies([body | parsed], bodies)
  end

  defp parse_locals(bin, count), do: parse_locals([], bin, count)
  defp parse_locals(parsed, bin, 0), do: {Enum.reverse(parsed), bin}

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

  defp find_block_pairs(instructions, idx \\ 0)
  defp find_block_pairs(instructions, idx) when idx == length(instructions), do: instructions

  defp find_block_pairs(instructions, idx) do
    instructions =
      case Enum.at(instructions, idx) do
        {:if, v} ->
          matched_else = find_matching(instructions, idx, :else)
          matched_end = find_matching(instructions, idx, :end)
          i = List.replace_at(instructions, idx, {:if, v, matched_else, matched_end})

          if matched_else != :none do
            List.replace_at(i, matched_else, {:else, matched_end})
          else
            i
          end

        {:block, v} ->
          matched_end = find_matching(instructions, idx, :end)
          List.replace_at(instructions, idx, {:block, v, matched_end})

        _ -> instructions
      end

    find_block_pairs(instructions, idx + 1)
  end

  defp find_matching(instructions, idx, type) do
    {_, instr} = Enum.split(instructions, idx + 1)

    match_idx =
      instr
      |> Enum.with_index()
      |> Enum.reduce_while(0, fn {instr, i}, depth ->
        if instr == type && depth == 0 do
          {:halt, i}
        else
          case instr do
            {:loop, _} -> {:cont, depth + 1}
            {:if, _} -> {:cont, depth + 1}
            {:block, _} -> {:cont, depth + 1}
            :end -> {:cont, depth - 1}
            _ -> {:cont, depth}
          end
        end
      end)

    if match_idx >= 0, do: idx + match_idx + 1, else: :none
  end
end
