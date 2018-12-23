defmodule WaspVM.Stack do
  alias WaspVM.Stack
  defstruct elements: []

  @moduledoc false

  @doc """
    Create a new stack
  """
  @spec new :: Stack
  def new, do: %Stack{}

  @doc """
    Adds a value to the top of a given stack
  """
  @spec push(Stack, any) :: Stack
  def push(stack, element) do
    %Stack{stack | elements: [element | stack.elements]}
  end

  @doc """
    Removes a value from the top of the stack and returns it along
    with the modified stack
  """
  @spec pop(Stack) :: {any, Stack}
  def pop(%Stack{elements: []}), do: raise("Stack is empty!")
  def pop(%Stack{elements: [top | rest]}) do
   {top, %Stack{elements: rest}}
  end

  @doc """
    Removes count number of items from the top of the stack
    and returns them along with the modified stack
  """
  @spec pop_multiple(Stack, integer) :: {any, Stack}
  def pop_multiple(%Stack{elements: elem}, count \\ 2) do
    {popped, rest} = Enum.split(elem, count)

    {popped, %Stack{elements: rest}}
  end

  @doc """
    Reads a single value from the stack without modifying the stack
  """
  @spec read(Stack) :: any
  def read(%Stack{elements: elem}), do: hd(elem)

  @doc """
    Reads count number of items from the stack without modifying the stack
  """
  @spec read_multiple(Stack, integer) :: list
  def read_multiple(%Stack{elements: elem}, count), do: Enum.take(elem, count)

  @doc """
    Returns the length of the stack
  """
  @spec depth(Stack) :: integer
  def depth(%Stack{elements: elements}), do: length(elements)
end
