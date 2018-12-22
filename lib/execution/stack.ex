defmodule WaspVM.Stack do
  alias WaspVM.Stack
  defstruct elements: []

  def new, do: %Stack{}

  def push(stack, element) do
    %Stack{stack | elements: [element | stack.elements]}
  end

  def pop(%Stack{elements: []}), do: raise("Stack is empty!")

  def pop(%Stack{elements: [top | rest]}) do
   {top, %Stack{elements: rest}}
  end

  def pop_multiple(%Stack{elements: elem}, count \\ 2) do
    {popped, rest} = Enum.split(elem, count)
    
    {popped, %Stack{elements: rest}}
  end

  def read(%Stack{elements: elem}), do: hd(elem)

  def read_multiple(%Stack{elements: elem}, count), do: Enum.take(elem, count)

  def depth(%WaspVM.Stack{elements: elements}), do: length(elements)
end
