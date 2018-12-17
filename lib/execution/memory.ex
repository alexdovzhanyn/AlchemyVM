defmodule WaspVM.Memory do
  defstruct pages: []

  def new(pages \\ 1) do
    mem =
      1
      |> Range.new(pages)
      |> Enum.map(fn _ ->
        <<0>>
        |> List.duplicate(1024 * 64)
        |> List.to_tuple
      end)

    %WaspVM.Memory{pages: mem}
  end

  def get_at(memory, address, bytes \\ 1, page \\ 0) do
    mem = Enum.at(memory.pages, page)

    for i <- address..(address + (bytes - 1)), into: <<>>, do: elem(mem, i)
  end

  def put_at(memory, address, bytes, page \\ 0) when is_binary(bytes) do
    mem = Enum.at(memory.pages, page)

    bytes = for <<byte::8 <- bytes>>, do: <<byte>>

    mem =
      bytes
      |> Enum.with_index()
      |> Enum.reduce(mem, fn {byte, idx}, acc -> put_elem(acc, address + idx, byte) end)

    pages = List.replace_at(memory.pages, page, mem)

    Map.put(memory, :pages, pages) |> IO.inspect
  end

end
