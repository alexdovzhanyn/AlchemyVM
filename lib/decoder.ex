defmodule WaspVM.Decoder do
  alias WaspVM.LEB128
  alias WaspVM.Module
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

    {section, rest} = decode_section(section_code, rest)

    module = Module.add_section(module, section_code, section)

    do_decode(module, rest)
  end

  defp decode_section(sec_code, bin) when sec_code > 0 do
    <<section_size::bytes-size(4), rest::binary>> = bin

    {size, remaining} = LEB128.decode(section_size)

    rest = remaining <> rest

    <<section::bytes-size(size), rest::binary>> = rest

    {section, rest}
  end

end
