defmodule WaspVM.LEB128 do

  def decode(<<x, rest::binary>>) when x < 128, do: {x, rest}

  def decode(<<x, rest::binary>>) when x >= 128 do
    {z, r} = decode(rest)
    {x - 128 + 128 * z, r}
  end

end
