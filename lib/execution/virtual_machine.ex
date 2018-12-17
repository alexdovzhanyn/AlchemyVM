defmodule WaspVM.VirtualMachine do
    use GenServer
    require IEx
    require Logger


    def start_link(args) do
      Logger.info("Virtual Machine Started")
      GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(args) do
      {:ok, %{vm: %{}, locals: [], filename: args[:filename]}}
    end

    def start_vm(args) do
      GenServer.cast(__MODULE__, {:start_vm, args})
    end

    def execute(args) do
      GenServer.cast(__MODULE__, {:execute, args})
    end

    def update(args) do
      GenServer.cast(__MODULE__, {:update, args})
    end

    def update_memory(args) do
      GenServer.cast(__MODULE__, {:update_memory, args})
    end

    def run_vm(args) do
      GenServer.cast(__MODULE__, {:run_vm, args})
    end

    def fetch() do
      GenServer.call(__MODULE__, :fetch)
    end

    def get_used() do
      GenServer.call(__MODULE__, :get_used)
    end

    def fetch_locals() do
      GenServer.call(__MODULE__, :fetch_locals)
    end

    def handle_call(:fetch, _from, state) do
      Logger.info("Received Fetch event")
      {:reply, state.vm, state}
    end

    def handle_call(:fetch_locals, _from, state) do
      Logger.info("Received Fetch Local event")
      {:reply, state.locals, state}
    end

    def handle_call(:get_used, _from, state) do
      Logger.info("Received Get Used Event")
      used = WaspVM.Memory.get_end(state.vm.memory)

      {:reply, used, state}
    end

    def handle_cast({:execute, args}, state) do
      Logger.info("Received Execute event")


      {:noreply, state}
    end

    def handle_cast({:start_vm, args}, state) do
      Logger.info("Received Start event")

      state = Map.put(state, :vm, args)
      {:noreply, state}
    end

    def handle_cast({:update_memory, args}, state) do
      Logger.info("Received Update Memory event")
      memory = WaspVM.Memory.put_at(state.vm.memory, args.index, args.value)
      vm = Map.put(state.vm, :memory, memory)
      state = Map.put(state, :vm, vm)
      {:noreply, state}
    end

    def handle_cast({:run_vm, args}, state) do
      Logger.info("Received Run event")
      state = Map.put(state, :locals, args)

      {:noreply, state}
    end

    def handle_cast({:update, args}, state) do
      Logger.info("Received Update event")
      IO.inspect args


      {:noreply, state}
    end


end
