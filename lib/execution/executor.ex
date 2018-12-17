defmodule WaspVM.Executor do
  require Logger

def execute(args) do
  Logger.info("Starting Execution of VM")
  vm = WaspVM.VirtualMachine.fetch()
  function_bodies = vm.module.functions |> Enum.map(fn function -> function.body end)
  result =
      function_bodies
      |> Enum.flat_map(fn inst ->
        Enum.reduce(inst, [], fn inst, acc -> [instruction(inst) | acc ] end)
      end)
end

def instruction({opcode, bytecode}), do: exec_inst(opcode, bytecode)
def instruction(opcode), do: exec_inst(opcode)

defp exec_inst(:i32_add) do
  total = WaspVM.VirtualMachine.get_used()
  #immediate = WaspVM.Memory.get_at(module.memory, 1, 1)
  #args + immediate
end

defp exec_inst(:end) do
:end
end

defp exec_inst(:get_local, bytecode) do
  locals = WaspVM.VirtualMachine.fetch_locals

  fetched_local = Enum.fetch!(locals, bytecode)

  WaspVM.VirtualMachine.update_memory(%{index: 0, value: <<2>>})
end

defp exec_inst(:i32_const, bytecode) do
WaspVM.VirtualMachine.update_memory(%{index: 1, value: <<2>>})
end

end
