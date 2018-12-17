defmodule WaspVM.VMTest do
  use ExUnit.Case, async: false
  doctest WaspVM

  test "Can exeucte basic vm" do
    WaspVM.start("./addTwo_main.wasm", [2])
  end

end
