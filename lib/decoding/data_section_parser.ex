defmodule AlchemyVM.Decoder.DataSectionParser do
  alias AlchemyVM.LEB128
  alias AlchemyVM.Decoder.Util

  @moduledoc false

  def parse(section) do
    {count, entries} = LEB128.decode_unsigned(section)

    entries = if count > 0, do: parse_entries(entries), else: []

    {:data, entries}
  end

  defp parse_entries(binary), do: parse_entries([], binary)
  defp parse_entries(parsed, <<>>), do: parsed
  defp parse_entries(parsed, binary) do
    {index, rest} = LEB128.decode_unsigned(binary)
    {offset, rest} = Util.evaluate_init_expr(rest)
    {size, rest} = LEB128.decode_unsigned(rest)
    <<data::bytes-size(size), rest::binary>> = rest

    entry = %{idx: index, offset: offset, data: data}

    parse_entries([entry | parsed], rest)
  end

end
