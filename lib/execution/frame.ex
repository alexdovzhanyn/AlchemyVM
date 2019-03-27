defmodule AlchemyVM.Frame do
  defstruct [:module, :instructions, :locals, :gas_limit, labels: [], snapshots: []]
  @moduledoc false
end
