defmodule WaspVM.VMManager do
  use GenServer
  require Logger
  require IEx

  def start_link(filename) do
    Logger.info("VM Manager Started")

    if filename == "" do
      Process.exit(self(), :kill)
    end

    module_name = String.replace(filename, [".","/", "wasm"], "")

    Supervisor.start_link(__MODULE__, module_name, name: __MODULE__)
  end

  def init(args) do
    children = [
      {WaspVM.VirtualMachine, args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
