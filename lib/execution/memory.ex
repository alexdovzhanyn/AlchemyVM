defmodule WaspVM.Memory do
  defstruct pages: []

  @moduledoc """
    Virtual Memory representation and interaction
  """

  @doc """
    Creates a new memory instance, with a given number of 64kb pages
  """
  @spec new(integer) :: WaspVM.Memory
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

  @doc """
    Gets N bytes from a given memory, starting at a given address
  """
  @spec get_at(WaspVM.Memory, integer, integer, integer) :: binary
  def get_at(memory, address, bytes \\ 1, page \\ 0) do
    mem = Enum.at(memory.pages, page)

    for i <- address..(address + (bytes - 1)), into: <<>>, do: elem(mem, i)
  end

  @doc """
    Writes bytes to memory at a given address
  """
  @spec put_at(WaspVM.Memory, integer, binary, integer) :: WaspVM.Memory
  def put_at(memory, address, bytes, page \\ 0) when is_binary(bytes) do
    mem = Enum.at(memory.pages, page)

    bytes = for <<byte::8 <- bytes>>, do: <<byte>>

    mem =
      bytes
      |> Enum.with_index()
      |> Enum.reduce(mem, fn {byte, idx}, acc -> put_elem(acc, address + idx, byte) end)

    pages = List.replace_at(memory.pages, page, mem)

    Map.put(memory, :pages, pages)
  end

end
