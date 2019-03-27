defmodule AlchemyVM.Decoder.TypeSectionParser do
  alias AlchemyVM.LEB128
  alias AlchemyVM.OpCodes

  @moduledoc false

  def parse(section) do
    {count, entries} = LEB128.decode_unsigned(section)

    entries =
      if count > 0 do
        entries
        |> String.split(OpCodes.type_to_opcode(:func))
        |> Enum.filter(& &1 != "")
        |> Enum.map(fn entry ->
          {types, entry} = parse_type_entry(entry)
          {return_types, _entry} = parse_type_entry(entry)

          {types, return_types}
        end)
      else
        []
      end

    {:types, entries}
  end

  defp parse_type_entry(entry) do
    {count, entry} = LEB128.decode_unsigned(entry)

    if count > 0 do
      <<the_types::bytes-size(count), rest::binary>> = entry

      type_codes = for <<opcode::8 <- the_types>>, do: OpCodes.opcode_to_type(<<opcode>>)

      {List.to_tuple(type_codes), rest}
    else
      {{}, entry}
    end
  end

end
