defmodule WaspVM do
  alias WaspVM.Decoder
  alias WaspVM.Stack
  alias WaspVM.Memory

  @enforce_keys [:module, :stack, :memory]
  defstruct [:module, :stack, :memory]

  def start(filename, args) do
    vm = WaspVM.VMManager.start_link(filename)
    module = load_file(filename)
    WaspVM.VirtualMachine.start_vm(module)
    WaspVM.VirtualMachine.run_vm(args)
    WaspVM.Executor.execute(args)
    WaspVM.VirtualMachine.fetch |> IO.inspect
  end

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

  def execute(file, args) do
    module = load_file(file)
    IO.inspect(module, lable: "MODULE")
    IO.inspect(args, label: "Arguments")
    module = Map.put(module, :locals, args)
    WaspVM.Executor.execute(module, args)
  end

  defp do_load(module) do
    %WaspVM{
      module: module,
      stack: Stack.new(),
      memory: Memory.new()
    }
  end

end
