defmodule WaspVM.Decoder.Util do
  alias WaspVM.LEB128

  @moduledoc false

  def decode_resizeable_limits(bin) do
    <<flags, rest::binary>> = bin
    {initial, rest} = LEB128.decode_unsigned(rest)

    if flags > 0 do
      {max, rest} = LEB128.decode_unsigned(rest)

      {%{initial: initial, max: max}, rest}
    else
      {%{initial: initial}, rest}
    end
  end

end
