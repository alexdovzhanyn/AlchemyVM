defmodule WaspVM.Decoder.ElementSectionParser do
  alias WaspVM.LEB128
  require IEx

  @moduledoc false

  def parse(section) do
    raise "Element section parser not implemented"

    {count, entries} = LEB128.decode_unsigned(section)

    entries = if count > 0, do: parse_entries(entries), else: []

    {:elements, entries}
  end

  defp parse_entries(entries), do: parse_entries([], entries)
  defp parse_entries(parsed, <<>>), do: parsed

  defp parse_entries(parsed, entries) do
    {index, entries} = LEB128.decode_unsigned(entries)

    end_opcode = 0x0b

    IEx.pry
  end

end
