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

defp exec_inst(stack, :i32_sub) do
  [a, b] = Enum.sum(Enum.take(stack, 2))
  stack = Enum.drop(stack, 2)
  [a - b | stack]
end

defp exec_inst(stack, :i32_mul) do
  [a, b] = Enum.sum(Enum.take(stack, 2))
  stack = Enum.drop(stack, 2)
  [a * b | stack]
end

defp exec_inst(stack, :i32_popcnt) do
  stack = Enum.drop(stack, 1)
  stack
end

defp exec_inst(stack, :i32_div_) do
  [a, b] = Enum.sum(Enum.take(stack, 2))
  stack = Enum.drop(stack, 2)
  [a / b | stack]
end

defp exec_inst(stack, :i32_rem_) do
  [a, b] = Enum.sum(Enum.take(stack, 2))
  stack = Enum.drop(stack, 2)
  [rem(a, b) | stack]
end

defp exec_inst(stack, :i32_or) do
  [a, b] = Enum.sum(Enum.take(stack, 2))
  stack = Enum.drop(stack, 2)
  value =
    case [a,b] do
      [<<0>>, <<1>>] -> <<1>>
      [<<0>>, <<0>>] -> <<0>>
      [<<1>>, <<1>>] -> <<1>>
    end
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
