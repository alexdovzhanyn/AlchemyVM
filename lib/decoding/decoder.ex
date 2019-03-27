defmodule AlchemyVM.Decoder do
  alias AlchemyVM.LEB128
  alias AlchemyVM.Module
  alias AlchemyVM.Decoder.TypeSectionParser
  alias AlchemyVM.Decoder.FunctionSectionParser
  alias AlchemyVM.Decoder.GlobalSectionParser
  alias AlchemyVM.Decoder.TableSectionParser
  alias AlchemyVM.Decoder.MemorySectionParser
  alias AlchemyVM.Decoder.ExportSectionParser
  alias AlchemyVM.Decoder.ImportSectionParser
  alias AlchemyVM.Decoder.StartSectionParser
  alias AlchemyVM.Decoder.ElementSectionParser
  alias AlchemyVM.Decoder.CodeSectionParser
  alias AlchemyVM.Decoder.CustomSectionParser
  alias AlchemyVM.Decoder.DataSectionParser
  require IEx

  @moduledoc false

  def decode_file(file_path, parallel \\ true) do
    {:ok, bin} = File.read(file_path)

    decode(bin, parallel)
  end

  def decode(bin, parallel \\ true)
  def decode(bin, parallel) when is_binary(bin), do: begin_split(bin, parallel)

  def decode(bin, _parallel) do
    {fun, arity} = __ENV__.function
    raise "Invalid data provided for #{fun}/#{arity}. Must be binary, got: #{inspect(bin)}"
  end

  defp begin_split(bin, parallel) do
    <<magic::bytes-size(4), version::bytes-size(4), rest::binary>> = bin

    if magic != <<0, 97, 115, 109>> do
      raise "Malformed or incomplete binary"
    else
      %Module{magic: magic, version: version}
      |> split_sections(rest, parallel)
      |> resolve_globals()
    end
  end

  defp split_sections(module, <<>>, true), do: parallel_decode(module)
  defp split_sections(module, <<>>, false), do: module

  defp split_sections(module, bin, parallel) do
    <<section_code, rest::binary>> = bin

    {unparsed_section, rest} = split_section(section_code, rest)

    module = Module.add_section(module, section_code, unparsed_section)

    module =
      if !parallel do
        section = Map.get(module.sections, section_code)
        {k, v} = parse_section({section_code, section})

        Map.put(module, k, v)
      else
        module
      end

    split_sections(module, rest, parallel)
  end

  defp split_section(sec_code, bin) when sec_code >= 0 do
    {size, rest} = LEB128.decode_unsigned(bin)

    <<section::bytes-size(size), rest::binary>> = rest

    {section, rest}
  end

  defp parallel_decode(module) do
    module.sections
    |> Task.async_stream(&parse_section/1, timeout: :infinity, max_concurrency: 12)
    |> Enum.reduce(module, fn {:ok, {k, v}}, a -> Map.put(a, k, v) end)
  end

  defp resolve_globals(module) do
    resolve = fn v ->
      if !is_number(v.offset) do
        [{:get_global, i}] = v.offset

        val = Enum.at(module.globals, i).initial

        Map.put(v, :offset, val)
      else
        v
      end
    end

    elements = Enum.map(module.elements, & resolve.(&1))
    data = Enum.map(module.data, & resolve.(&1))

    Map.merge(module, %{elements: elements, data: data})
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
  defp parse_section({11, section}), do: DataSectionParser.parse(section)
  defp parse_section({_, section}), do: section
end
