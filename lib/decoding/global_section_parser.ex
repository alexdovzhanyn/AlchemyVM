defmodule WaspVM.Decoder.GlobalSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Decoder.Util
  require IEx

  @moduledoc false

  def parse(section) do
    {count, entries} = LEB128.decode_unsigned(section)

    globals =
      if count > 0 do
        entries
        |> parse_entries()
        |> Enum.reverse()
        |> resolve_globals()
      else
        []
      end

    {:globals, globals}
  end

  defp parse_entries(entries), do: parse_entries([], entries)
  defp parse_entries(parsed, <<>>), do: parsed

  defp parse_entries(parsed, entries) do
    {opcode, entries} = LEB128.decode_unsigned(entries)

    type = OpCodes.opcode_to_type(<<opcode>>)

    {mutability, entries} = LEB128.decode_unsigned(entries)

    mutable = mutability == 1

    {initial, entries} = Util.evaluate_init_expr(entries)

    global = %{type: type, mutable: mutable, initial: initial}

    parse_entries([global | parsed], entries)
  end

  defp resolve_globals(globals), do: Enum.map(globals, & resolve_global(&1, globals))

  defp resolve_global(%{initial: i} = glob, _globals) when is_number(i), do: glob
  defp resolve_global(%{initial: [{_, i}]}, globals) do
    globals
    |> Enum.at(i)
    |> resolve_global(globals)
  end
end
