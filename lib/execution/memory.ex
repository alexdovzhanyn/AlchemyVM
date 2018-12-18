defmodule WaspVM.Memory do
  alias WaspVM.Memory
  require IEx
  defstruct pages: []

  @moduledoc """
    Virtual Memory representation and interaction
  """

  @doc """
    Creates a new memory instance, with a given number of 64kb pages
  """
  @spec new(integer) :: Memory
  def new(pages \\ 1) do
    mem =
      1
      |> Range.new(pages)
      |> Enum.map(fn _ -> initialize_empty_mem() end)

    %Memory{pages: mem}
  end

  @doc """
    Gets N bytes from a given memory, starting at a given address
  """
  @spec get_at(Memory, integer, integer) :: binary
  def get_at(memory, address, bytes \\ 1) do
    mem = Enum.at(memory.pages, calculate_page_for_address(address))

    for i <- address..(address + (bytes - 1)), into: <<>>, do: elem(mem, i)
  end

  def get_end(memory, page \\ 0) do
    mem = Enum.at(memory.pages, page)
    # Need to implement
  end

  @doc """
    Writes bytes to memory at a given address
  """
  @spec put_at(Memory, integer, binary) :: Memory
  def put_at(memory, address, bytes) when is_binary(bytes) do
    page = calculate_page_for_address(address)
    mem = Enum.at(memory.pages, page)

    bytes = for <<byte::8 <- bytes>>, do: <<byte>>

    # Will have issues if writing to last few bytes in page if
    # bytes > bytes remaining in page. Will fix later

    mem =
      bytes
      |> Enum.with_index()
      |> Enum.reduce(mem, fn {byte, idx}, acc -> put_elem(acc, address + idx, byte) end)

    pages = List.replace_at(memory.pages, page, mem)

    Map.put(memory, :pages, pages)
  end

  @doc """
    Grow memory by N pages
  """
  @spec grow(Memory, integer) :: Memory
  def grow(memory, pages) do
    new_pages =
      1
      |> Range.new(pages)
      |> Enum.map(fn _ -> initialize_empty_mem() end)

    Map.put(memory, :pages, memory.pages ++ new_pages)
  end

  defp initialize_empty_mem do
    <<0>>
    |> List.duplicate(1024 * 64)
    |> List.to_tuple()
  end

  defp calculate_page_for_address(address), do: div(address, 1024 * 64)

end
