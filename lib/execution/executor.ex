defmodule WaspVM.Executor do

@args 2
@bytecode 2

def execute(module, args) do
  functions = module.module.functions
  function_bodies = functions |> Enum.map(fn function -> function.body end)
  result =
    function_bodies
    |> Enum.flat_map(fn inst ->
      Enum.reduce(inst, [], fn inst, acc -> [ instruction(inst) | acc] end)
    end)
end

def instruction({opcode, bytecode}), do: exec_inst(opcode, bytecode)
def instruction(opcode), do: exec_inst(opcode)



defp exec_inst(:i32_add) do
@args + @bytecode
end

defp exec_inst(:end) do
:end
end

defp exec_inst(:get_local, bytecode) do
# byte code is local index of immediate variable i.e arg 0,1
# push bytecode to stack
@args
end

defp exec_inst(:i32_const, bytecode) do
#byte code is immediate constant
#bytecode is constant from function body
bytecode
end

end
