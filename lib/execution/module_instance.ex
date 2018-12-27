defmodule WaspVM.ModuleInstance do
  alias WaspVM.ModuleInstance
  alias WaspVM.Module
  alias WaspVM.Memory
  alias WaspVM.Store
  require IEx

  defstruct ref: nil,
            funcaddrs: [],
            tableaddrs: [],
            memaddrs: [],
            globaladdrs: [],
            exports: [],
            types: []

  @moduledoc false

  # Module instantiation as described at
  # https://webassembly.github.io/spec/core/exec/modules.html#alloc-module

  @spec new :: ModuleInstance
  def new, do: %ModuleInstance{ref: make_ref()}

  @spec instantiate(ModuleInstance, Module, Store) :: {ModuleInstance, Store}
  def instantiate(instance, module, store) do
    {memaddrs, store} =
      module.memory
      |> initialize_memories()
      |> Enum.map_reduce(store, fn mem, s ->
        {:ok, addr, updated_s} = Store.allocate_memory(s, mem)

        {addr, updated_s}
      end)

    {funcaddrs, store} =
      module
      |> initialize_funcs(instance.ref)
      |> Enum.map_reduce(store, fn func, s ->
        {:ok, addr, updated_s} = Store.allocate_func(s, func)

        {addr, updated_s}
      end)

    funcaddrs =
      funcaddrs
      |> Enum.with_index()
      |> Enum.map(fn {k, v} -> {v, k} end)
      |> Map.new()

    {globaladdrs, store} =
      Enum.map_reduce(module.globals, store, fn glob, s ->
        {:ok, addr, updated_s} = Store.allocate_global(s, glob)

        {addr, updated_s}
      end)

    # TODO: Implement table initialization
    instance = Map.merge(instance, %{
      memaddrs: memaddrs,
      funcaddrs: funcaddrs,
      globaladdrs: globaladdrs,
      types: module.types
    })

    # Exports need to happen after everything else is initialized
    exports = Enum.map(module.exports, & generate_export(instance, &1))

    instance = Map.put(instance, :exports, exports)

    {instance, store}
  end

  @doc """
    Initialize a new memory. Module can only define 1 memory in the MVP
    so we're creating a list with 1 item, but in the future this may grow
  """
  @spec initialize_memories(map | nil) :: list
  def initialize_memories(nil), do: []
  def initialize_memories(memory), do: [Memory.new(memory)]

  @doc """
    Initialize all function instances defined in a given module
  """
  @spec initialize_funcs(Module, reference) :: list
  def initialize_funcs(module, ref) do
    host_funcs =
      module.imports
      |> Enum.filter(& &1.type == :typeidx)
      |> Enum.map(fn imp ->
        type = Enum.at(module.types, imp.index)

        {:hostfunc, type, imp.module, imp.field}
      end)

    funcs =
      module.functions
      |> Enum.with_index()
      |> Enum.map(fn {func, idx} ->
        typeidx = Enum.at(module.function_types, idx)
        type = Enum.at(module.types, typeidx)
        locals = Enum.flat_map(func.locals, & List.duplicate(0, &1.count))

        {type, ref, func.body, locals}
      end)

    host_funcs ++ funcs
  end

  def generate_export(moduleinst, %{kind: kind, index: index, name: name}) do
    if kind == :func do
      %{^index => addr} = moduleinst.funcaddrs
      {name, addr}
    end
  end
end
