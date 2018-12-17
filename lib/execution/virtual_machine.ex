defmodule WaspVM.VirtualMachine do
    use GenServer
    require IEx
    require Logger


    def start_link(args) do
      Logger.info("Virtual Machine Started")
      GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(args) do
      {:ok, %{vm: %{}, locals: []}}
    end

    def start_vm(args) do
      GenServer.cast(__MODULE__, {:start_vm, args})
    end

    def run_vm(args) do
      GenServer.cast(__MODULE__, {:run_vm, args})
    end

    def fetch() do
      GenServer.call(__MODULE__, :fetch)
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


    def handle_cast({:start_vm, args}, state) do
      Logger.info("Received Start event")

      state = Map.put(state, :vm, args)
      {:noreply, state}
    end

    def handle_cast({:run_vm, args}, state) do
      Logger.info("Received Run event")
      state = Map.put(state, :locals, args)

      {:noreply, state}
    end


end
