defmodule Math do
  use WaspVM.HostFunction

  defhost add(<<a::integer-32-little>>, <<b::integer-32-little>>) do
    <<(a + b)::integer-32-little>>
  end

  defhost subtract(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    <<(a - b)::integer-32-little>>
  end

  defhost multiply(<<a::integer-32-little>>, <<b::integer-32-little>>) do
    <<(a * b)::integer-32-little>>
  end

  defhost divide(<<b::integer-32-little>>, <<a::integer-32-little>>) do
    <<div(a, b)::integer-32-little>>
  end
end
