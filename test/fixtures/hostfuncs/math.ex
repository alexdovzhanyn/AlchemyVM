defmodule Math do
  use AlchemyVM.HostFunction

  defhost add(a, b) do
    a + b
  end

  defhost subtract(b, a) do
    a - b
  end

  defhost multiply(a, b) do
    a * b
  end

  defhost divide(b, a) do
    a / b
  end
end
