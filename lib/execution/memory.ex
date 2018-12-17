defmodule WaspVM.Memory do
  defstruct pages: []

  def new, do: %WaspVM.Memory{}

end
