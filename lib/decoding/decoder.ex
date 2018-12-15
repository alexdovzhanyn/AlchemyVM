defmodule WaspVM.Decoder do
  alias WaspVM.LEB128
  alias WaspVM.Module
  alias WaspVM.Decoder.TypeSectionParser
  require IEx

  def decode_file(file_path) do
    {:ok, bin} = File.read(file_path)

    decode(bin)
  end

  def decode(bin) when is_binary(bin), do: do_decode(%Module{}, bin)

  @doc false
  def decode(bin) do
    {fun, arity} = __ENV__.function
    raise "Invalid data provided for #{fun}/#{arity}. Must be binary, got: #{inspect(bin)}"
  end

  defp do_decode(module, <<>>), do: module

  defp do_decode(module, bin) when module == %Module{} do
    <<magic::bytes-size(4), version::bytes-size(4), rest::binary>> = bin

    if magic != <<0, 97, 115, 109>> do
      raise "Malformed or incomplete binary"
    else
      do_decode(%Module{magic: magic, version: version}, rest)
    end
  end

  defp do_decode(module, bin) do
    <<section_code, rest::binary>> = bin

    {unparsed_section, rest} = decode_section(section_code, rest)

    module =
      module
      |> Module.add_section(section_code, unparsed_section)
      |> parse_section(section_code)

    do_decode(module, rest)
  end

  defp decode_section(sec_code, bin) when sec_code > 0 do
    {size, rest} = LEB128.decode(bin)

    <<section::bytes-size(size), rest::binary>> = rest

    {section, rest}
  end

  defp parse_section(module, 1), do: TypeSectionParser.parse(module)

end
