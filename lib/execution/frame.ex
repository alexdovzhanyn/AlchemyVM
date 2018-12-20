defmodule WaspVM.Frame do
  defstruct [:module, :instructions, :locals, :next_instr]

end
