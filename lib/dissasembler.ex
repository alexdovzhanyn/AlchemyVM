defmodule WaspVM.Dissasembler do

  @spec dissasemble(Binary, Integer, Map) :: Tuple
  def disassemble(_bin, _addr, _dissasembled), do: {:error, "Disassembler should be called with an empty map"}
  def dissasemble(bin, addr, dissasembled), do: instruction(bin, addr, [:start_block], dissasembled)


  @spec instruction(Binary, Integer, List, Map) :: Tuple
  defp instruction(bin, addr, stack, dissasembled), do: {:ok, ""}
  defp instruction(bin, addr, [], dissasembled), do: {:ok, {dissasembled, addr}, bin}

end
