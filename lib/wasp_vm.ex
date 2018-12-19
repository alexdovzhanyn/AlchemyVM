defmodule WaspVM do
  use GenServer
  alias WaspVM.Decoder
  alias WaspVM.Stack
  alias WaspVM.ModuleInstance
  alias WaspVM.Store
  alias WaspVM.Frame
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

  def trap(reason) do
    GenServer.cast(ref, {:trap, reason})
  end

  def handle_cast({:trap, reason}, _from, vm) do
    Logger.warn("EXITING STACK MACHINE: #{reason}")
    Process.exit(self(), :normal)
    {:noreply, vm}
  end

  def execute(ref, func, args \\ []) do
    GenServer.call(ref, {:execute, func, args}, :infinity)
  end

  def handle_call({:load_module, module}, _from, vm) do
    {moduleinst, store} = ModuleInstance.instantiate(ModuleInstance.new(), module, vm.store)

    modules = [moduleinst | vm.modules]

    {:reply, :ok, Map.merge(vm, %{modules: modules, store: store})}
  end

  def handle_call({:execute, fname, args}, _from, vm) do
    {func_addr, module} =
      Enum.find_value(vm.modules, fn module ->
        a =
          Enum.find_value(module.exports, fn {name, addr} ->
            if name == fname, do: addr, else: false
          end)

        if a, do: {a, module}, else: {:not_found, 0}
      end)

    {reply, vm} =
      case func_addr do
        :not_found -> {{:error, :no_exported_function, fname}, vm}
        addr -> execute_func(vm, addr, module, args)
      end

    {:reply, reply, vm}
  end

  @spec execute_func(WaspVM, integer, ModuleInstance, list) :: tuple
  defp execute_func(vm, addr, module, args) do
    {{inputs, _outputs}, _module_ref, instr, locals} = Enum.at(vm.store.funcs, addr)

    {res, vm} =
      if tuple_size(inputs) != length(args) do
        {{:error, :param_mismatch, tuple_size(inputs), length(args)}, vm}
      else
        frame = %Frame{
          module: module,
          instructions: instr,
          locals: args ++ Enum.map(locals, fn _ -> 0 end),
          next_instr: 0
        }

        final_vm = Executor.execute(frame, vm)

        result =
          if final_vm.stack.elements == [] do
            :ok
          else
            {:ok, hd(final_vm.stack.elements)}
          end

        {result, final_vm}
      end
    {res, vm}
  end
end
