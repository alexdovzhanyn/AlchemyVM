defmodule WaspVM.DSL do

  defmacro __using__(_opts) do
    quote do
      import WaspVM.DSL
    end
  end

  defmacro definstr(head, do: block) do
    {opname, args_ast} = Macro.decompose_call(head)

    {opname, args_ast} =
      case List.last(args_ast) do
        [immediates: immediates] ->
          op = {:{}, [], [opname | immediates]}
          [_ | args] = Enum.reverse(args_ast)
          args = Enum.reverse(args)

          {op, args}

        _ -> {opname, args_ast}
      end

    num_args = length(args_ast)

    quote generated: true do
      defp instruction(var!(ctx), var!(gas), s, var!(opts), unquote(opname)) do
        {unquote(args_ast), var!(stack)} = Enum.split(s, unquote(num_args))

        unquote(block)
      end
    end
  end

end


# definstr i32_add(a, b) do
#   stack = [a + b |  stack]
# end
