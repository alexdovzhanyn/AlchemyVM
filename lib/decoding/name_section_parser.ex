defmodule WaspVM.Decoder.NameSectionParser do
  alias WaspVM.LEB128

  def parse(binary) do
    binary
    |> parse_subsections()
    |> Map.new()
  end

  defp parse_subsections(binary), do: parse_subsections([], binary)
  defp parse_subsections(parsed, <<>>), do: parsed
  defp parse_subsections(parsed, binary) do
    <<name_type, rest::binary>> = binary
    {name_payload_len, rest} = LEB128.decode_unsigned(rest)
    <<name_payload_data::bytes-size(name_payload_len), rest::binary>> = rest

    name_type =
      case name_type do
        0 -> :module
        1 -> :function
        2 -> :local
      end

    subsection = parse_subsection(name_type, name_payload_data)

    parse_subsections([{name_type, subsection} | parsed], rest)
  end

  defp parse_subsection(:module, binary) do
    binary
  end

  defp parse_subsection(:function, binary) do
    {count, rest} = LEB128.decode_unsigned(binary)

    {sub, _rest} = if count > 0, do: parse_name_map(rest, count), else: %{}

    sub
  end

  defp parse_subsection(:local, binary) do
    {count, rest} = LEB128.decode_unsigned(binary)

    if count > 0, do: parse_local_names(rest), else: %{}
  end

  defp parse_local_names(binary), do: parse_local_names(%{}, binary)
  defp parse_local_names(parsed, <<>>), do: parsed
  defp parse_local_names(parsed, binary) do
    {index, rest} = LEB128.decode_unsigned(binary)
    {count, rest} = LEB128.decode_unsigned(rest)
    {local_map, rest} = if count > 0, do: parse_name_map(rest, count), else: {%{}, rest}

    parse_local_names(Map.put(parsed, index, local_map), rest)
  end

  defp parse_name_map(binary, count), do: parse_name_map(%{}, binary, count)
  defp parse_name_map(parsed, binary, 0), do: {parsed, binary}
  defp parse_name_map(parsed, binary, count) do
    {index, rest} = LEB128.decode_unsigned(binary)
    {name_len, rest} = LEB128.decode_unsigned(rest)
    <<name_str::bytes-size(name_len), rest::binary>> = rest

    parse_name_map(Map.put(parsed, index, name_str), rest, count - 1)
  end

end
