defmodule WaspVM.VirtualMachine do
    use GenServer
    require IEx
    require Logger


    def start_link(args) do
      Logger.info("Virtual Machine Started")
      GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end

    def init(args) do
      #to add module load
      {:ok, %{state: "New"}}
    end

    def execute do
      GenServer.cast(__MODULE__, :execute)
    end

    def handle_cast(:execute, state) do
        Logger.info("Received Execute event")


      {:noreply, state}
    end


end
