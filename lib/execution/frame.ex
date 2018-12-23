defmodule WaspVM.Frame do
  defstruct [:module, :instructions, :locals, :next_instr, labels: [], snapshots: []]
  @moduledoc false
end
