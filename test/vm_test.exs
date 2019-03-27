defmodule AlchemyVM.VMTest do
  use ExUnit.Case, async: false
  doctest AlchemyVM

  test "Can start the vm" do
    res = AlchemyVM.start()
    assert {:ok, _} = res
  end

end
