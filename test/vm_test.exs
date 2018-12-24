defmodule WaspVM.VMTest do
  use ExUnit.Case, async: false
  doctest WaspVM

  test "Can start the vm" do
    res = WaspVM.start()
    assert {:ok, _} = res
  end

end
