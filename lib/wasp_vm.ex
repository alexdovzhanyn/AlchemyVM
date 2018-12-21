defmodule WaspVM do
  use GenServer
  alias WaspVM.Decoder
  alias WaspVM.Stack
  alias WaspVM.ModuleInstance
  alias WaspVM.Store
  alias WaspVM.Executor
  require IEx

  @enforce_keys [:modules, :stack, :store]
  defstruct [:modules, :stack, :store]

  def start, do: GenServer.start_link(__MODULE__, [])

  def init(_args) do
    {
      :ok,
      %WaspVM{
        modules: [],
        stack: Stack.new(),
        store: %Store{}
      }
    }
  end

  def load_file(ref, filename) do
    GenServer.call(ref, {:load_module, Decoder.decode_file(filename)}, :infinity)
  end

  def load(ref, binary) when is_binary(binary) do
    GenServer.call(ref, {:load_module, Decoder.decode(binary)}, :infinity)
  end

  def execute(ref, func, args \\ []) do
    GenServer.call(ref, {:execute, func, args}, :infinity)
  end

  def vm_state(ref), do: GenServer.call(ref, :vm_state, :infinity)

  def handle_call({:load_module, module}, _from, vm) do
    {moduleinst, store} = ModuleInstance.instantiate(ModuleInstance.new(), module, vm.store)

    modules = [moduleinst | vm.modules]

    {:reply, :ok, Map.merge(vm, %{modules: modules, store: store})}
  end

  def handle_call({:execute, fname, args}, _from, vm) do
    {func_addr, _module} =
      Enum.find_value(vm.modules, fn module ->
        a =
          Enum.find_value(module.exports, fn export ->
            if export !== nil do
              {name, addr} = export
              if name == fname, do: addr, else: false
            else
              false
            end
          end)

        if a, do: {a, module}, else: {:not_found, 0}
      end)

    {reply, vm} =
      case func_addr do
        :not_found -> {{:error, :no_exported_function, fname}, vm}
        addr -> execute_func(vm, addr, args)
      end

    {:reply, reply, vm}
  end

  def handle_call(:vm_state, _from, vm), do: {:reply, vm, vm}

  @spec execute_func(WaspVM, integer, list) :: tuple
  defp execute_func(vm, addr, args) do
    stack = Enum.reduce(args, vm.stack, fn arg, s -> Stack.push(s, arg) end)

    vm =
      vm
      |> Map.put(:stack, stack)
      |> Executor.create_frame_and_execute(addr)

    case vm do
      tuple when is_tuple(tuple) -> tuple
      _ -> {{:ok, hd(vm.stack.elements)}, vm}
    end
  end
end
