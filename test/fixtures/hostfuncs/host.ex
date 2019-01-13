defmodule Host do
  use WaspVM.HostFunction

  defhost "function0", [a, b] do
    IO.inspect(a)
    IO.inspect(b)
    IO.inspect vm
    # |> WaspVM.get_memory("memory1")
    # |> WaspVM.Memory.put_at(0, <<50, 130, 53>>) # 3310133
    # |> WaspVM.Memory.put_at(32, <<102, 20, 75>>) # 6689867
  end
  #
  # defhost :hello do
  #   IO.puts "HI"
  # end
  #
  # defhost :goodbye do
  #   IO.puts "HI"
  # end
  #
  # defhost "zepelli" do
  #   IO.puts "HI"
  # end
end
