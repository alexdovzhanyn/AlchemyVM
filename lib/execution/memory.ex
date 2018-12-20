defmodule WaspVM.Memory do
  alias WaspVM.Memory
  require IEx

  defstruct data: {},
            limit: :infinity

  @page_size 0x10000 # 64 KiB

  @moduledoc """
    Virtual Memory representation and interaction
  """

  @doc """
    Creates a new memory instance, with a given number of 64kb pages
  """
  @spec new(map) :: Memory
  def new(memory_immediate) do
    mem = initialize_empty_mem(memory_immediate.initial)

    %Memory{data: mem, limit: Map.get(memory_immediate, :max, :infinity)}
  end

  @doc """
    Gets N bytes from a given memory, starting at a given address
  """
  @spec get_at(Memory, integer, integer) :: binary
  def get_at(memory, address, bytes \\ 1) do
    for i <- address..(address + (bytes - 1)), into: <<>>, do: elem(memory.data, i)
  end

  @doc """
    Writes bytes to memory at a given address
  """
  @spec put_at(Memory, integer, binary) :: Memory
  def put_at(memory, address, bytes) when is_binary(bytes) do
    bytes = for <<byte::8 <- bytes>>, do: <<byte>>

    mem =
      bytes
      |> Enum.with_index()
      |> Enum.reduce(memory.data, fn {byte, idx}, acc ->
        put_elem(acc, address + idx, byte)
      end)

    Map.put(memory, :data, mem)
  end

  @doc """
    Grow memory by N pages
  """
  @spec grow(Memory, integer) :: Memory
  def grow(memory, pages) do
    new_mem = initialize_empty_mem(pages)

    mem = List.to_tuple(Tuple.to_list(memory.data) ++ Tuple.to_list(new_mem))

    Map.put(memory, :data, mem)
  end

  defp initialize_empty_mem(pages) do
    <<0>>
    |> List.duplicate(@page_size * pages)
    |> List.to_tuple()
  end
end
