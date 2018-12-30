defmodule WaspVM.Decoder.StartSectionParser do
  alias WaspVM.LEB128

  @moduledoc false

   def parse(section) do
     {index, _entries} = LEB128.decode_unsigned(section)

     {:start, index}
   end

end
