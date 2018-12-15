defmodule WaspVM.Decoder.MemorySectionParser do
  alias WaspVM.LEB128

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(5)
      |> LEB128.decode()

    # Right now each module can have only 1 memory entry.
    # Might have to refactor this if a new version of Wasm
    # allows for multiple memory section entries
    entries =
      if count > 0 do
        <<flags, rest::binary>> = entries

        {initial, rest} = LEB128.decode(rest)

        entry = %{initial: initial}

        if flags == 1 do
          {max, _rest} = LEB128.decode(rest)

          Map.put(entry, :max, max)
        else
          entry
        end
      else
        []
      end

    Map.put(module, :memory, entries)
  end

end
