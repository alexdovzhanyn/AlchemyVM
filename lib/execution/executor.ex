defmodule WaspVM.Executor do
  require Logger

def execute(args) do
  Logger.info("Starting Execution of VM")
  vm = WaspVM.VirtualMachine.fetch()
  function_bodies = vm.module.functions |> Enum.map(fn function -> function.body end)
  result =
      function_bodies
      |> Enum.flat_map(fn inst ->
        Enum.reduce(inst, [], fn inst, stack ->
          stack = instruction(stack, inst)
      end)
      end)
end

def instruction(stack, opcode) when is_atom(opcode), do: exec_inst(stack, opcode)
def instruction(stack, {opcode, bytecode}), do: exec_inst(stack, opcode, bytecode)


defp exec_inst(stack, :i32_add) do
  value = Enum.sum(Enum.take(stack, 2))
  stack = Enum.drop(stack, 2)
  [value | stack]
end

defp exec_inst(stack, :end) do
  stack
end

defp exec_inst(stack, :get_local, bytecode) do
  locals = WaspVM.VirtualMachine.fetch_locals
  local = Enum.fetch!(locals, bytecode)
  [local | stack]
end

defp exec_inst(stack, :i32_const, bytecode) do
 [bytecode | stack]
end

end
