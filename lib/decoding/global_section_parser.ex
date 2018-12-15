defmodule WaspVM.Decoder.GlobalSectionParser do
  alias WaspVM.LEB128
  alias WaspVM.OpCodes
  alias WaspVM.Module

  def parse(module) do
    {count, entries} =
      module.sections
      |> Map.get(6)
      |> LEB128.decode()

    #Uses Dissambler, leaving for now
    globals =
      if count > 0 do
        <<flags, rest::binary>> = entries

        {nglobals, rest} = LEB128.decode(rest)

      else
        %{}
      end

    Map.put(module, :globals, globals)
  end



end
