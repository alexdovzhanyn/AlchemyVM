defmodule StackTest do
  use ExUnit.Case

  alias WaspVM.Stack


  test "Creates Stack" do
    assert Stack.new() == %Stack{}
  end

  test "Pushes Elements to a stack" do
    stack = Stack.new
    |> Stack.push(1)
    |> Stack.push(2)

    assert stack.elements == [2, 1]
  end

  test "Pops Elements from a stack" do
    {popped, stack} = Stack.new
    |> Stack.push(1)
    |> Stack.push(2)
    |> Stack.pop()

    assert stack.elements == [1]
  end


end
