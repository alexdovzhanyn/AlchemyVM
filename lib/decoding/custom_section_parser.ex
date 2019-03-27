defmodule AlchemyVM.Decoder.CustomSectionParser do
  alias AlchemyVM.Decoder.NameSectionParser
  alias AlchemyVM.LEB128

  @moduledoc false

  def parse(section) do
    {name_len, rest} = LEB128.decode_unsigned(section)

    <<name::bytes-size(name_len), rest::binary>> = rest

    section = parse_section(name, rest)

    custom = Map.new([{String.to_atom(name), section}])

    {:custom, custom}
  end

  def parse_section("name", binary), do: NameSectionParser.parse(binary)
  def parse_section(name, _), do: raise "Parser for custom section #{name} not implemented"

end
