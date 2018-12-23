defmodule WaspVM.Decoder.ExportSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  require IEx

  @moduledoc false

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(7)
      |> LEB128.decode_unsigned()

    entries = if count > 0, do: parse_entries(entries), else: []
    entries = entries |> Enum.reject(&(&1 == nil))

    Map.put(module, :exports, Enum.reverse(entries))
  end

  defp parse_entries(entries), do: parse_entries([], entries)
  defp parse_entries(parsed, <<>>), do: parsed

  defp parse_entries(parsed, entries) do
    {field_len, entries} = LEB128.decode_unsigned(entries)

    <<field_str::bytes-size(field_len), kind, entries::binary>> = entries

    {index, entries} = LEB128.decode_unsigned(entries)

    entry = %{
      name: field_str,
      kind: OpCodes.external_kind(kind),
      index: index
    }

    parse_entries([entry | parsed], entries)
  end

end
