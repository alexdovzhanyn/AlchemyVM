defmodule WaspVM.Executor do
  alias WaspVM.Stack
  alias WaspVM.Memory
  require Logger
  require IEx

  def execute(instructions, vm) when is_list(instructions) do
    Enum.reduce(instructions, vm, & instruction(&2, &1))
  end

  def instruction(vm, opcode) when is_atom(opcode), do: exec_inst(vm, opcode)
  def instruction(vm, op) when is_tuple(op), do: exec_inst(vm, op)

  defp exec_inst(vm, {:i32_const, i32}) do
    Map.put(vm, :stack, Stack.push(vm.stack, i32))
  end

  defp exec_inst(vm, {:i32_store, alignment, offset}) do
    {[value, address], stack} = Stack.pop_multiple(vm.stack, 2)

    binary_val = <<value::32>>

    mem = Memory.put_at(vm.memory, address + offset, binary_val)

    Map.merge(vm, %{memory: mem, stack: stack})
  end

  defp exec_inst(vm, {:i32_load, alignment, offset}) do
    {address, stack} = Stack.pop(vm.stack)

    <<i32::32>> = Memory.get_at(vm.memory, address + offset, 4)

    Map.put(vm, :stack, Stack.push(stack, i32))
  end

  defp exec_inst(vm, {:get_local, idx}) do
    local = Enum.at(vm.locals, idx)

    Map.put(vm, :stack, Stack.push(vm.stack, local))
  end

  defp exec_inst(vm, {:set_local, idx}) do
    {value, stack} = Stack.pop(vm.stack)

    locals = List.replace_at(vm.locals, idx, value)

    Map.merge(vm, %{locals: locals, stack: stack})
  end

  defp exec_inst(vm, :i32_add) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack, 2)
    Map.put(vm, :stack, Stack.push(stack, a + b))
  end

  defp exec_inst(vm, :end), do: vm

  defp exec_inst(vm, op) do
    IEx.pry
  end

  defp exec_inst(vm, :i32_sub) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack, 2)
    Map.put(vm, :stack, Stack.push(stack, a - b))
  end

  defp exec_inst(vm, :i32_mul) do
    {[a, b], stack} = Stack.pop_multiple(vm.stack, 2)

    Map.put(vm, :stack, Stack.push(stack, a * b))
  end

  # Sign-agnostic count number of one bits
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

  defp exec_inst(stack, :get_local, bytecode) do
    locals = WaspVM.VirtualMachine.fetch_locals
    local = Enum.fetch!(locals, bytecode)
    [local | stack]
  end

end
