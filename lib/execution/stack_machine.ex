defmodule WaspVM.StackMachine do
  use GenServer
  require IEx
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([vm]), do: {:ok, vm}

  def execute(ref, func, args) do
    GenServer.call(ref, {:execute, func, args}, :infinity)
  end

  def fetch() do
    GenServer.call(__MODULE__, :fetch)
  end

  def fetch_locals() do
    GenServer.call(__MODULE__, :fetch_locals)
  end

  def handle_call({:execute, fname, args}, _from, vm) do
    {res, vm} =
      case Enum.find(vm.module.exports, & &1.name == fname && &1.kind == :func) do
        nil -> {{:error, :no_exported_function, fname}, vm}
        %{index: i} ->
          function = Enum.at(vm.module.functions, i)

          # Fix this later (shouldn't be -1)
          func_type_idx = Enum.at(vm.module.function_types, i - 1)

          {inputs, outputs} = Enum.at(vm.module.types, func_type_idx)

          if tuple_size(inputs) != length(args) do
            {{:error, :param_mismatch, tuple_size(inputs), length(args)}}
          else
            configured_vm = configure_vm(vm, inputs, args, function.locals)

            updated_vm =
              function.body
              |> WaspVM.Executor.execute(configured_vm)
              |> reset_vm()

            result =
              if updated_vm.stack.elements == [] do
                :ok
              else
                {:ok, hd(updated_vm.stack.elements)}
              end

            {result, updated_vm}
          end
      end

    {:reply, res, vm}
  end

  def handle_call(:fetch, _from, vm) do
    Logger.info("Received Fetch event")
    {:reply, vm, vm}
  end

  def handle_call(:fetch_locals, _from, vm) do
    Logger.info("Received Fetch Local event")
    {:reply, vm.locals, vm}
  end

  # Super crude, will fix later
  defp configure_vm(vm, inputs, args, locals) do
    locals = Enum.map(locals, fn _ -> 0 end)

    Map.put(vm, :locals, args ++ locals)
  end

  defp reset_vm(vm), do: Map.put(vm, :locals, [])
end
