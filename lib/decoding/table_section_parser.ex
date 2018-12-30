defmodule WaspVM.Decoder.TableSectionParser do
  alias WaspVM.LEB128

  @moduledoc false

  def parse(section) do
    {count, entries} = LEB128.decode_unsigned(section)

    entries =
      # Not correct. Only parses first item out
      if count > 0 do
        <<flags, rest::binary>> = entries

        {min, rest} = LEB128.decode_unsigned(rest)

        entry = %{min: min}

        if flags == 1 do
          {max, _rest} = LEB128.decode_unsigned(rest)

          Map.put(entry, :max, max)
        else
          entry
        end
      else
        []
      end

    {:table, entries}
  end

end
