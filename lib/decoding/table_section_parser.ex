defmodule WaspVM.Decoder.TableSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Module

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(4)
      |> LEB128.decode()


    entries =
      if count > 0 do
        <<flags, rest::binary>> = entries

        {min, rest} = LEB128.decode(rest)

        entry = %{min: min}

        if flags == 1 do
          {max, _rest} = LEB128.decode(rest)

          Map.put(entry, :max, max)
        else
          entry
        end
      else
        []
      end

    Map.put(module, :table, {entries})
  end


end
