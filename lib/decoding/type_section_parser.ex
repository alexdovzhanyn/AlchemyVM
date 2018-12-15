defmodule WaspVM.Decoder.TypeSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(1)
      |> LEB128.decode()

    if count > 0 do
      entries =
        entries
        |> String.split(OpCodes.type_to_opcode(:func))
        |> Enum.filter(& &1 != "")
        |> Enum.map(fn entry ->
          {types, entry} = parse_type_entry(entry)
          {return_types, _entry} = parse_type_entry(entry)

          {types, return_types}
        end)

      Map.put(module, :types, entries)
    else
      []
    end
  end

  defp parse_type_entry(entry) do
    {count, entry} = LEB128.decode(entry)

    if count > 0 do
      <<the_types::bytes-size(count), rest::binary>> = entry

      type_codes = for <<opcode::8 <- the_types>>, do: OpCodes.opcode_to_type(<<opcode>>)

      {List.to_tuple(type_codes), rest}
    else
      {{}, entry}
    end
  end

end
