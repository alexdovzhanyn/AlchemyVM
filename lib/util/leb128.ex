defmodule WaspVM.LEB128 do

  def decode_unsigned(<<n, rest::binary>>) when n < 128, do: {n, rest}
  def decode_unsigned(<<n, rest::binary>>) when n >= 128 do
    {m, rest} = decode_unsigned(rest)
    {n - 128 + 128 * m, rest}
  end

  def decode_signed(<<n, rest::binary>>) when n < 64, do: {n, rest}
  def decode_signed(<<n, rest::binary>>) when n >= 64 and n < 128, do: {n - 128, rest}
  def decode_signed(<<n, rest::binary>>) when n >= 128 do
    {m, rest} = decode_signed(rest)
    {n - 128 + 128 * m, rest}
  end
end
