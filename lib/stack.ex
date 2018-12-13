defmodule ExWasm.Stack do

defstruct elements: []

def new, do: %ExWasm.Stack{}

def push(stack, element) do
 %ExWasm.Stack{stack | elements: [element | stack.elements]}
 end

def pop(%ExWasm.Stack{elements: []}), do: raise("Stack is empty!")
 def pop(%ExWasm.Stack{elements: [top | rest]}) do
 {top, %ExWasm.Stack{elements: rest}}
 end

def depth(%ExWasm.Stack{elements: elements}), do: length(elements)
 end
