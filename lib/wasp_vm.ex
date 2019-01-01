defmodule WaspVM do
  use GenServer
  alias WaspVM.Decoder
  alias WaspVM.ModuleInstance
  alias WaspVM.Store
  alias WaspVM.Executor
  require IEx

  @enforce_keys [:modules, :store]
  defstruct [:modules, :store]

  @moduledoc """
    Execute WebAssembly code
  """

  @doc """
    Starts the Virtual Machine and returns the PID which is used to
    interface with the VM.
  """
  @spec start :: {:ok, pid}
  def start, do: GenServer.start_link(__MODULE__, [])

  @doc false
  def init(_args) do
    {
      :ok,
      %WaspVM{
        modules: %{},
        store: %Store{}
      }
    }
  end

  @doc """
    Load a binary WebAssembly file (.wasm) as a module into the VM
  """

  @spec load_file(pid, String.t()) :: {:ok, WaspVM.Module}
  def load_file(ref, filename) do
    GenServer.call(ref, {:load_module, Decoder.decode_file(filename)}, :infinity)
  end

  @doc """
    Load a WebAssembly module directly from a binary into the VM
  """

  @spec load(pid, binary) :: {:ok, WaspVM.Module}
  def load(ref, binary) when is_binary(binary) do
    GenServer.call(ref, {:load_module, Decoder.decode(binary)}, :infinity)
  end

  @doc """
    Load a module that was already decoded by load/3 or load_file/3. This is useful
    for caching modules, as it skips the entire decoding step.
  """
  @spec load_module(pid, WaspVM.Module) :: {:ok, WaspVM.Module}
  def load_module(ref, module) do
    GenServer.call(ref, {:load_module, module}, :infinity)
  end

  @doc """
    Call an exported function by name from the VM. The function must have
    been loaded in through a module using load_file/2 or load/2 previously
  """
  @spec execute(pid, String.t(), list) :: :ok | {:ok, any} | {:error, any}
  def execute(ref, func, args \\ [], opts \\ []) do
    GenServer.call(ref, {:execute, func, args, opts}, :infinity)
  end

  @doc """
    Returns the state for a given VM instance
  """
  @spec vm_state(pid) :: WaspVM
  def vm_state(ref), do: GenServer.call(ref, :vm_state, :infinity)

  def handle_call({:load_module, module}, _from, vm) do
    {moduleinst, store} = ModuleInstance.instantiate(ModuleInstance.new(), module, vm.store)

    modules = Map.put(vm.modules, moduleinst.ref, moduleinst)

    {:reply, {:ok, module}, Map.merge(vm, %{modules: modules, store: store})}
  end

  def handle_call({:execute, fname, args, opts}, _from, vm) do
    {func_addr, _module} =
      vm.modules
      |> Map.values()
      |> Enum.find_value(fn module ->
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
        addr ->
          if opts[:gas_limit] == nil do
            execute_func(vm, addr, args, false)
          else
            execute_func(vm, addr, args, opts[:gas_limit])
          end
      end

    {:reply, reply, vm}
  end

  def handle_call(:vm_state, _from, vm), do: {:reply, vm, vm}

  @spec execute_func(WaspVM, integer, list, boolean) :: tuple
  defp execute_func(vm, addr, args, gas_limit) do
    stack = Enum.reduce(args, [], & [&1 | &2])

    {vm, gas, stack} = Executor.create_frame_and_execute(vm, addr, stack, gas_limit)

    case vm do
      tuple when is_tuple(tuple) -> tuple
      _ -> {{:ok, gas, hd(stack)}, vm}
    end
  end
end
