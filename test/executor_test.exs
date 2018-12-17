defmodule WaspVM.ExecutorTest do
  use ExUnit.Case
  doctest WaspVM

  test "Can exeucte basic vm" do
    WaspVM.execute("./addTwo_main.wasm", [2])
  end

end
