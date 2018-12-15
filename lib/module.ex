defmodule WaspVM.Module do

  defstruct sections: %{},
            magic: nil,
            version: nil,
            types: nil,
            memory: nil,
            exports: nil,
            imports: nil,
            function_types: nil,
            table: nil,
            start: nil

  def add_section(module, sec_code, section) do
    sections = Map.put(module.sections, sec_code, section)

    Map.put(module, :sections, sections)
  end

end
