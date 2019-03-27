defmodule AlchemyVM.DSL do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      import AlchemyVM.DSL
    end
  end

  @doc """
    This allows us to internally write OpCode definition instructions in a more
    concise format.

    We can write the following definition:

    defop i32_add(a, b) do
      stack = [a + b |  stack]
      {ctx, gas + Gas.cost(:i32_add), stack}
    end

    and it will generate the following code:

    defp instruction(ctx, gas, [a, b | stack], _opts, :i32_add) do
      stack = [a + b |  stack]
      {ctx, gas + Gas.cost(:i32_add), stack}
    end

    In the above example, the i32_add(a, b) will implicitly pull values off the
    stack and assign them to their respective variables.

    When we have opcodes that are tuples rather than just atoms (opcodes that
    have immediates, like i32_const), we can specify their immediates like so:

    defop i32_const(immediates: [i32]) do
      ...
    end

    This gets translated to

    defp instruction(ctx, gas, stack, _opts, {:i32_const, i32}) do
      ...
    end
  """
  defmacro defop(head, do: block) do
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
      defp instruction({var!(frame), var!(vm), var!(ip)} = var!(ctx), var!(gas), s, var!(opts), unquote(opname)) do
        {unquote(args_ast), var!(stack)} = Enum.split(s, unquote(num_args))

        unquote(block)
      end
    end
  end

end
