defmodule WaspVM.Decoder.ImportSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Decoder.Util

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(2)
      |> LEB128.decode()

    entries = if count > 0, do: parse_entries(entries), else: []

    Map.put(module, :imports, entries)
  end

  defp parse_entries(entries), do: parse_entries([], entries)
  defp parse_entries(parsed, <<>>), do: parsed

  defp parse_entries(parsed, entries) do
    {module_len, entries} = LEB128.decode(entries)

    <<module_str::bytes-size(module_len), entries::binary>> = entries

    {field_len, entries} = LEB128.decode(entries)

    <<field_str::bytes-size(field_len), kind, entries::binary>> = entries

    kind = OpCodes.external_kind(kind)

    entry = %{
      module: module_str,
      field: field_str
    }

    {entry, entries} =
      case kind do
        :func ->
          {index, entries} = LEB128.decode(entries)

          entry =
            entry
            |> Map.put(:type, :typeidx)
            |> Map.put(:index, index)

          {entry, entries}

        :table ->
          <<opcode::bytes-size(1), entries::binary>> = entries
          elem_type = OpCodes.opcode_to_type(opcode)

          {resizeable_limits, entries} = Util.decode_resizeable_limits(entries)

          entry =
            entry
            |> Map.put(:type, :table)
            |> Map.put(:table, resizeable_limits)
            |> Map.put(:elem_type, elem_type)

          {entry, entries}

        :mem ->
          {resizeable_limits, entries} = Util.decode_resizeable_limits(entries)

          entry =
            entry
            |> Map.put(:type, :mem)
            |> Map.put(:mem, resizeable_limits)

          {entry, entries}

        :global ->
          <<opcode::bytes-size(1), entries::binary>> = entries
          content_type = OpCodes.opcode_to_type(opcode)

          <<mutability, entries::binary>> = entries

          entry =
            entry
            |> Map.put(:type, :global)
            |> Map.put(:content_type, content_type)
            |> Map.put(:mutability, mutability)

          {entry, entries}
      end

    parse_entries([entry | parsed], entries)
  end
end
