defmodule WaspVM.Executor do


def execute(module, args) do
  functions = module.module.functions
  function_bodies = functions |> Enum.map(fn function -> function.body end)
  result =
    function_bodies
    |> Enum.flat_map(fn inst ->
      Enum.reduce(inst, module, fn inst, acc -> instruction(module, inst) end)
    end)
end

def instruction(module, {opcode, bytecode}), do: exec_inst(module, opcode, bytecode)
def instruction(module, opcode), do: exec_inst(module, opcode)

defp exec_inst(module, :i32_add) do
  #args = WaspVM.Memory.get_at(module.memory, 0, 1)
  #immediate = WaspVM.Memory.get_at(module.memory, 1, 1)
  #args + immediate
end

defp exec_inst(module, :end) do
:end
end

defp exec_inst(module, :get_local, bytecode) do
# byte code is local index of immediate variable i.e arg 0,1
# push bytecode to stack
  memory = WaspVM.Memory.put_at(module.memory, 0, <<2>>)
  Map.put(module, :memory, memory)
end

defp exec_inst(module, :i32_const, bytecode) do
  IO.inspect(module.memory, label: "MEMORY", limit: :infinity)
#byte code is immediate constant
#bytecode is constant from function body
  #WaspVM.Memory.put_at(module.memory, 0, bytecode)
end

end
