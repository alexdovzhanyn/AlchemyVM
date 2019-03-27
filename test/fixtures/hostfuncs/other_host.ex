defmodule OtherHost do
  use AlchemyVM.HostFunction

  defhost function0 do
    IO.puts "Hey there"
  end
end
