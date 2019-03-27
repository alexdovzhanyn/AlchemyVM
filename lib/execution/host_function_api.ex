defmodule AlchemyVM.HostFunction.API do
  alias AlchemyVM.Helpers
  use Agent

  @moduledoc """
    Provides an API for interacting with the VM from within a host function
  """

  @doc false
  def child_spec(arg), do: child_spec(arg)

  @doc false
  def start_link(vm), do: Agent.start_link(fn -> vm end)

  @doc false
  def stop(pid), do: Agent.stop(pid)

  @doc false
  @spec state(pid) :: AlchemyVM
  def state(pid), do: Agent.get(pid, & &1)

  @doc """
    Returns x number of bytes from a given exported memory, starting at the specified
    address

  ## Usage

  When within a host function body defined by `defhost`, if called from a WebAssembly
  module that has an exported memory called "memory1", and the memory is laid
  out as such: `{0, 0, 0, 0, 0, 0, 0, 0, 243, 80, 45, 92, ...}`, it can be accessed
  by doing:

      defhost get_from_memory do
        <<243, 80, 45, 92>> = AlchemyVM.HostFunction.API.get_memory(ctx, "memory1", 8, 4)
      end

  Note that `ctx` here is a variable defined by the `defhost` macro in order
  to serve as a pointer to VM state.
  """
  @spec get_memory(pid, String.t(), integer, integer) :: binary | {:error, :no_exported_mem, String.t()}
  def get_memory(pid, mem_name, address, bytes \\ 1) do
    vm = state(pid)

    case Helpers.get_export_by_name(vm, mem_name, :mem) do
      :not_found -> {:error, :no_exported_mem, mem_name}
      addr ->
        vm.store.mems
        |> Enum.at(addr)
        |> AlchemyVM.Memory.get_at(address, bytes)
    end
  end

  @doc """
    Updates a given exported memory with the given bytes, at the specified address

  ## Usage

  When within a host function body defined by `defhost`, if called from a WebAssembly
  module that has an exported memory called "memory1", it can be updated
  by doing:

      defhost update_memory do
        AlchemyVM.HostFunction.API.update_memory(ctx, "memory1", 0, <<"hello world">>)
      end

  This will set the value of "memory1" to `{"h", "e", "l", "l", "o", " ", "w",
  "o", "r", "l", "d", ...}`

  Note that `ctx` here is a variable defined by the `defhost` macro in order
  to serve as a pointer to VM state.
  """
  @spec update_memory(pid, String.t(), integer, binary) :: :ok | {:error, :no_exported_mem, String.t()}
  def update_memory(pid, mem_name, address, bytes) do
    vm_state = state(pid)

    case Helpers.get_export_by_name(vm_state, mem_name, :mem) do
      :not_found -> {:error, :no_exported_mem, mem_name}
      addr ->
        Agent.update(pid, fn vm ->
          mem =
            vm.store.mems
            |> Enum.at(addr)
            |> AlchemyVM.Memory.put_at(address, bytes)

          mems = List.replace_at(vm.store.mems, addr, mem)
          store = Map.put(vm.store, :mems, mems)

          Map.put(vm, :store, store)
        end)

        :ok
    end
  end
end
