defmodule WaspVM.Frame do
  defstruct [:module, :instructions, :locals, labels: [], snapshots: []]
  @moduledoc false
end
