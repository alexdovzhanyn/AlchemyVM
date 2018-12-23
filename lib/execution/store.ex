defmodule WaspVM.Store do
  require IEx
  alias WaspVM.Memory
  alias WaspVM.Store

  defstruct funcs: [],
            mems: [],
            globals: [],
            tables: []

  @moduledoc false

  # The store represents all global state that can be manipulated
  # by WebAssembly programs. It consists of the runtime representation
  # of all instances of functions, tables, memories, and globals that
  # have been allocated during the life time of the abstract machine.

  @doc """
    Allocate new memory to the store. Returns a tuple with the address
    of the allocated memory and the new store.
  """
  @spec allocate_memory(Store, Memory) :: {:ok, integer, Store}
  def allocate_memory(store, memory) do
    index = length(store.mems)
    mems = List.insert_at(store.mems, index, memory)

    {:ok, index, Map.put(store, :mems, mems)}
  end

  @doc """
    Allocate a function to the store. Returns a tuple with the address
    of the allocated function and the new store.
  """
  @spec allocate_func(Store, map) :: {:ok, integer, Store}
  def allocate_func(store, func) do
    index = length(store.funcs)
    funcs = List.insert_at(store.funcs, index, func)

    {:ok, index, Map.put(store, :funcs, funcs)}
  end

  @doc """
    Allocate a global to the store. Returns a tuple with the address
    of the allocated global and the new store.
  """
  @spec allocate_global(Store, map) :: {:ok, integer, Store}
  def allocate_global(store, global) do
    index = length(store.globals)
    globals = List.insert_at(store.globals, index, global)

    {:ok, index, Map.put(store, :globals, globals)}
  end
end
