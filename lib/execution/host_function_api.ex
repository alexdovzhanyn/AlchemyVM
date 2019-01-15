defmodule WaspVM.HostFunction.API do
  alias WaspVM.Helpers
  use Agent

  @doc false
  def start_link(vm), do: Agent.start_link(fn -> vm end)

  @doc false
  def stop(pid), do: Agent.stop(pid)

  @doc false
  def state(pid), do: Agent.get(pid, & &1)

  def get_memory(pid, mem_name, address, bytes \\ 1) do
    vm = state(pid)

    case Helpers.get_export_by_name(vm, mem_name, :mem) do
      :not_found -> {:error, :no_exported_mem, mem_name}
      addr ->
        vm.store.mems
        |> Enum.at(addr)
        |> WaspVM.Memory.get_at(address, bytes)
    end
  end

  def update_memory(pid, mem_name, address, bytes) do
    vm_state = state(pid)

    case Helpers.get_export_by_name(vm_state, mem_name, :mem) do
      :not_found -> {:error, :no_exported_mem, mem_name}
      addr -> Agent.update(pid, fn vm ->
        mem =
          vm.store.mems
          |> Enum.at(addr)
          |> WaspVM.Memory.put_at(address, bytes)

        mems = List.replace_at(vm.store.mems, addr, mem)
        store = Map.put(vm.store, :mems, mems)

        Map.put(vm, :store, store)
      end)
    end
  end
end
