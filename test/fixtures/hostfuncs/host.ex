defmodule Host do
  use WaspVM.HostFunction

  defhost function0(_a, _b) do
    WaspVM.HostFunction.API.update_memory(ctx, "memory1", 0, <<53, 130, 50, 0>>) # 3310133
    WaspVM.HostFunction.API.update_memory(ctx, "memory1", 32, <<75, 20, 102, 0>>) # 6689867
  end

  defhost function1 do
    IO.puts "HI"
  end

  defhost fill_mem_at_locations(<<addr1::integer-32-little>>, <<addr2::integer-32-little>>) do
    WaspVM.HostFunction.API.update_memory(ctx, "memory1", addr1, <<53, 130, 50, 0>>) # 3310133
    WaspVM.HostFunction.API.update_memory(ctx, "memory1", addr2, <<75, 20, 102, 0>>) # 6689867
  end

  defhost log(a) do
    IO.puts a
  end
end
