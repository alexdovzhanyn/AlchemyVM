defmodule OtherHost do
  use WaspVM.HostFunction

  defhost :function0 do
    IO.puts "Hey there"
  end
end
