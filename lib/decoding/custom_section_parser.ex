defmodule WaspVM.Decoder.CustomSectionParser do
  alias WaspVM.Decoder.NameSectionParser
  alias WaspVM.LEB128

  @moduledoc false

  def parse(module) do
    {name_len, rest} =
      module.sections
      |> Map.get(0)
      |> LEB128.decode_unsigned()

    <<name::bytes-size(name_len), rest::binary>> = rest

    section = parse_section(name, rest)

    custom = Map.put(module.custom, String.to_atom(name), section)

    Map.put(module, :custom, custom)
  end

  def parse_section("name", binary), do: NameSectionParser.parse(binary)
  def parse_section(name, _), do: raise "Parser for custom section #{name} not implemented"

end
