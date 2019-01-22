defmodule WaspVM do
  use GenServer
  alias WaspVM.Decoder
  alias WaspVM.ModuleInstance
  alias WaspVM.Store
  alias WaspVM.Executor
  alias WaspVM.Helpers
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
  def init(_args), do: {:ok, %WaspVM{modules: %{}, store: %Store{}}}

  @doc """
    Load a binary WebAssembly file (.wasm) as a module into the VM
  """
  @spec load_file(pid, String.t(), map) :: {:ok, WaspVM.Module}
  def load_file(ref, filename, imports \\ %{}) do
    GenServer.call(ref, {:load_module, Decoder.decode_file(filename), imports}, :infinity)
  end

  @doc """
    Load a WebAssembly module directly from a binary into the VM
  """
  @spec load(pid, binary, map) :: {:ok, WaspVM.Module}
  def load(ref, binary, imports \\ %{}) when is_binary(binary) do
    GenServer.call(ref, {:load_module, Decoder.decode(binary), imports}, :infinity)
  end

  @doc """
    Load a module that was already decoded by load/3 or load_file/3. This is useful
    for caching modules, as it skips the entire decoding step.
  """
  @spec load_module(pid, WaspVM.Module, map) :: {:ok, WaspVM.Module}
  def load_module(ref, module, imports \\ %{}) do
    GenServer.call(ref, {:load_module, module, imports}, :infinity)
  end

  @doc """
    Call an exported function by name from the VM. The function must have
    been loaded in through a module using load_file/2 or load/2 previously

  ## Usage
  ### Most basic usage for a simple module (no imports or host functions):

  #### Wasm File (add.wat)
  ```
  (module
   (func (export "basic_add") (param i32 i32) (result i32)
    get_local 0
    get_local 1
    i32.add
   )
  )
  ```
  Use an external tool to compile add.wat to add.wasm (compile from text
  representation to binary representation)

      {:ok, pid} = WaspVM.start() # Start the VM
      WaspVM.load_file(pid, "path/to/add.wasm") # Load the module that contains our add function

      # Call the add function, passing in 3 and 10 as args
      {:ok, gas, result} = WaspVM.execute(pid, "basic_add", [3, 10])

  ### Executing modules with host functions:

  #### Wasm file (log.wat)
  ```
  (module
    (import "env" "consoleLog" (func $consoleLog (param f32)))
    (export "getSqrt" (func $getSqrt))
    (func $getSqrt (param f32) (result f32)
      get_local 0
      f32.sqrt
      tee_local 0
      call $consoleLog

      get_local 0
    )
  )
  ```
  Use an external tool to compile log.wat to log.wasm (compile from text
  representation to binary representation)

      {:ok, pid} = WaspVM.start() # Start the VM

      # Define the imports used in this module. Keys in the import map
      # must be strings
      imports = %{
        "env" => %{
          "consoleLog" => fn x -> IO.puts "its \#{x}" end
        }
      }

      # Load the file, passing in the imports
      WaspVM.load_file(pid, "path/to/log.wasm", imports)

      # Call getSqrt with an argument of 25
      WaspVM.execute(pid, "getSqrt", [25])

  Program execution can also be limited by specifying a `:gas_limit` option:

      WaspVM.execute(pid, "some_func", [], gas_limit: 100)

  This will stop execution of the program if the accumulated gas exceeds 100
  """
  @spec execute(pid, String.t(), list, list) :: :ok | {:ok, any} | {:error, any}
  def execute(ref, func, args \\ [], opts \\ []) do
    opts = Keyword.merge([gas_limit: :infinity], opts)

    GenServer.call(ref, {:execute, func, args, opts}, :infinity)
  end

  @doc """
    Retrieve a Virtual Memory set from the VM. Memory must have been exported
    from the WebAssembly module in order to be accessible here.
  """
  @spec get_memory(pid, String.t()) :: WaspVM.Memory
  def get_memory(ref, mem_name) do
    GenServer.call(ref, {:get_mem, mem_name}, :infinity)
  end

  @doc """
    Write to a module's exported memory directly. Memory must have been exported
    from the WebAssembly module in order to be accessible here.
  """
  @spec update_memory(pid, String.t(), WaspVM.Memory) :: WaspVM
  def update_memory(ref, mem_name, mem) do
    GenServer.call(ref, {:update_mem, mem_name, mem}, :infinity)
  end

  @doc """
    Returns the state for a given VM instance
  """
  @spec vm_state(pid) :: WaspVM
  def vm_state(ref), do: GenServer.call(ref, :vm_state, :infinity)

  @spec run_start(integer) :: none
  defp run_start(start_addr), do: GenServer.cast(self(), {:start, start_addr})

  def handle_call({:load_module, module, imports}, from, vm) do
    module = Map.put(module, :resolved_imports, imports)

    {moduleinst, store} = ModuleInstance.instantiate(ModuleInstance.new(), module, vm.store)

    modules = Map.put(vm.modules, moduleinst.ref, moduleinst)

    vm = Map.merge(vm, %{modules: modules, store: store})

    if module.start do
      startidx = module.start
      %{^startidx => start_addr} = moduleinst.funcaddrs

      {:reply, {:ok, module}, vm, {:continue, {:start, start_addr}}}
    else
      {:reply, {:ok, module}, vm}
    end
  end

  def handle_call({:execute, fname, args, opts}, _from, vm) do
    {reply, vm} =
      case Helpers.get_export_by_name(vm, fname, :func) do
        :not_found -> {{:error, :no_exported_function, fname}, vm}
        addr -> execute_func(vm, addr, args, opts[:gas_limit])
      end

    {:reply, reply, vm}
  end

  def handle_continue({:start, start_addr}, vm) do
    {_, vm} = execute_func(vm, start_addr, [], :infinity)

    {:noreply, vm}
  end

  def handle_call({:get_mem, mname}, _from, vm) do
    reply =
      case Helpers.get_export_by_name(vm, mname, :mem) do
        :not_found -> {:error, :no_exported_mem, mname}
        addr -> Enum.at(vm.store.mems, addr)
      end

    {:reply, reply, vm}
  end

  def handle_call({:update_mem, mname, mem}, _from, vm) do
    case Helpers.get_export_by_name(vm, mname, :mem) do
      :not_found -> {:reply, {:error, :no_exported_mem, mname}, vm}
      addr ->
        mems = List.replace_at(vm.store.mems, addr, mem)
        store = Map.put(vm.store, :mems, mems)
        reply = Map.put(vm, :store, store)
        {:reply, reply, reply}
    end
  end

  def handle_call(:vm_state, _from, vm), do: {:reply, vm, vm}

  @spec execute_func(WaspVM, integer, list, :infinity | integer) :: tuple
  defp execute_func(vm, addr, args, gas_limit) do
    stack = Enum.reduce(args, [], & [&1 | &2])

    {vm, gas, stack} = Executor.create_frame_and_execute(vm, addr, gas_limit, 0, stack)

    case vm do
      tuple when is_tuple(tuple) -> tuple
      _ -> {{:ok, gas, List.first(stack)}, vm}
    end
  end
end
