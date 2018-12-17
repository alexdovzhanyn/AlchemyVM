defmodule WaspVM.Stack do
  defstruct elements: []

  def new, do: %WaspVM.Stack{}

  def push(stack, element) do
    %WaspVM.Stack{stack | elements: [element | stack.elements]}
  end

  def pop(%WaspVM.Stack{elements: []}), do: raise("Stack is empty!")

  def pop(%WaspVM.Stack{elements: [top | rest]}) do
   {top, %WaspVM.Stack{elements: rest}}
  end

  def depth(%WaspVM.Stack{elements: elements}), do: length(elements)
end
