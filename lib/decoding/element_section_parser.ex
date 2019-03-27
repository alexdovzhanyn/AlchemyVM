defmodule AlchemyVM.Decoder.ElementSectionParser do
  alias AlchemyVM.LEB128
  alias AlchemyVM.Decoder.Util
  require IEx

  @moduledoc false

  def parse(section) do
    {count, entries} = LEB128.decode_unsigned(section)

    entries = if count > 0, do: parse_entries(entries), else: []

    {:elements, entries}
  end

  defp parse_entries(entries), do: parse_entries([], entries)
  defp parse_entries(parsed, <<>>), do: parsed

  defp parse_entries(parsed, entries) do
    {index, entries} = LEB128.decode_unsigned(entries)
    {offset, entries} = Util.evaluate_init_expr(entries)
    {count, entries} = LEB128.decode_unsigned(entries)

    {indices, entries} = if count > 0, do: parse_indices(entries, count), else: []

    entry = %{table_idx: index, offset: offset, indices: indices}

    parse_entries([entry | parsed], entries)
  end

  defp parse_indices(bin, count), do: parse_indices([], bin, count)
  defp parse_indices(parsed, bin, 0), do: {parsed, bin}
  defp parse_indices(parsed, bin, count) do
    {idx, rest} = LEB128.decode_unsigned(bin)

    parse_indices([idx | parsed], rest, count - 1)
  end

end
