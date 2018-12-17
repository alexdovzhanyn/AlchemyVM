defmodule WaspVM.Supervisor do
  alias WaspVM.StackMachine
  use Supervisor

  def start_link(vm) do
    Supervisor.start_link(__MODULE__, [vm])
  end

  def init(args), do: Supervisor.init([{StackMachine, args}], strategy: :one_for_one)

end
