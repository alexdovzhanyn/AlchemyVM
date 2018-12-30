defmodule WaspVM.Decoder do
  alias WaspVM.LEB128
  alias WaspVM.Module
  alias WaspVM.Decoder.TypeSectionParser
  alias WaspVM.Decoder.FunctionSectionParser
  alias WaspVM.Decoder.GlobalSectionParser
  alias WaspVM.Decoder.TableSectionParser
  alias WaspVM.Decoder.MemorySectionParser
  alias WaspVM.Decoder.ExportSectionParser
  alias WaspVM.Decoder.ImportSectionParser
  alias WaspVM.Decoder.StartSectionParser
  alias WaspVM.Decoder.ElementSectionParser
  alias WaspVM.Decoder.CodeSectionParser
  alias WaspVM.Decoder.CustomSectionParser
  require IEx

  @moduledoc false

  def decode_file(file_path) do
    {:ok, bin} = File.read(file_path)

    decode(bin)
  end

  @doc false
  def decode(bin) when is_binary(bin), do: split_sections(%Module{}, bin)

  @doc false
  def decode(bin) do
    {fun, arity} = __ENV__.function
    raise "Invalid data provided for #{fun}/#{arity}. Must be binary, got: #{inspect(bin)}"
  end

  defp split_sections(module, <<>>), do: parallel_decode(module)

  defp split_sections(module, bin) when module == %Module{} do
    <<magic::bytes-size(4), version::bytes-size(4), rest::binary>> = bin

    if magic != <<0, 97, 115, 109>> do
      raise "Malformed or incomplete binary"
    else
      split_sections(%Module{magic: magic, version: version}, rest)
    end
  end

  defp split_sections(module, bin) do
    <<section_code, rest::binary>> = bin

    {unparsed_section, rest} = split_section(section_code, rest)

    module = Module.add_section(module, section_code, unparsed_section)

    split_sections(module, rest)
  end

  defp split_section(sec_code, bin) when sec_code >= 0 do
    {size, rest} = LEB128.decode_unsigned(bin)

    <<section::bytes-size(size), rest::binary>> = rest

    {section, rest}
  end

  defp parallel_decode(module) do
    module.sections
    |> Task.async_stream(&parse_section/1)
    |> Enum.reduce(module, fn {k, v}, a -> Map.put(a, k, v) end)

    # module.sections
    # |> Stream.map(fn {k, _} -> Task.async(fn -> parse_section(module, k) end) end)
    # |> Stream.map(&Task.await/1)
    # |> Enum.reduce(&Map.merge(&2, &1))
  end

  defp parse_section({0, section}), do: CustomSectionParser.parse(section)
  defp parse_section({1, section}), do: TypeSectionParser.parse(section)
  defp parse_section({2, section}), do: ImportSectionParser.parse(section)
  defp parse_section({3, section}), do: FunctionSectionParser.parse(section)
  defp parse_section({4, section}), do: TableSectionParser.parse(section)
  defp parse_section({5, section}), do: MemorySectionParser.parse(section)
  defp parse_section({6, section}), do: GlobalSectionParser.parse(section)
  defp parse_section({7, section}), do: ExportSectionParser.parse(section)
  defp parse_section({8, section}), do: StartSectionParser.parse(section)
  defp parse_section({9, section}), do: ElementSectionParser.parse(section)
  defp parse_section({10, section}), do: CodeSectionParser.parse(section)
  defp parse_section({_, section}), do: section

end
