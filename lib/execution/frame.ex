defmodule WaspVM.Frame do
  alias WaspVM.Frame

  defstruct [:module, :instructions, :locals, :next_instr]

end
