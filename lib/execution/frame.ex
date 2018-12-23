defmodule WaspVM.Frame do
  defstruct [:module, :instructions, :locals, :next_instr, labels: []]
  @moduledoc false
end
