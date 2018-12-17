defmodule WaspVM do
  alias WaspVM.Decoder
  alias WaspVM.Stack
  alias WaspVM.Memory
  alias WaspVM.StackMachine

  @enforce_keys [:module, :stack, :memory]
  defstruct [:module, :stack, :memory, locals: []]

  def load_file(filename) do
    filename
    |> Decoder.decode_file()
    |> do_load()
  end

  def load(binary) when is_binary(binary) do
    binary
    |> Decoder.decode()
    |> do_load
  end

  defp do_load(module) do
    vm = %WaspVM{
      module: module,
      stack: Stack.new(),
      memory: Memory.new()
    }

    {:ok, sup} = WaspVM.Supervisor.start_link(vm)

    [{_, vm_pid, _, _}] = Supervisor.which_children(sup)

    vm_pid
  end

  def execute(vm, func, args \\ []), do: StackMachine.execute(vm, func, args)
end
