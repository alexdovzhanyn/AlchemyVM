defmodule WaspVM.Decoder.StartSectionParser do
  alias WaspVM.LEB128

  @moduledoc false

   def parse(module) do
     {index, _entries} =
       module.sections
       |> Map.get(8)
       |> LEB128.decode_unsigned()

     Map.put(module, :start, index)
   end

end
