defmodule AlchemyVM.Helpers do

  @moduledoc false

  @spec get_export_by_name(AlchemyVM, String.t(), atom) :: integer | :not_found
  def get_export_by_name(vm, mname, type) do
    vm.modules
    |> Map.values()
    |> Enum.find_value(fn module ->
      a =
        Enum.find_value(module.exports, fn export ->
          try do
            {^type, name, addr} = export
            if name == mname, do: addr, else: false
          rescue
            _ -> false
          end
        end)

      if a, do: a, else: :not_found
    end)
  end
end
