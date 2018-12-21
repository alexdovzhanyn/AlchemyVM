defmodule WaspVM.Module do

  defstruct sections: %{},
            magic: nil,
            version: nil,
            types: [],
            memory: nil,
            exports: [],
            imports: [],
            function_types: [],
            table: nil,
            start: nil,
            functions: [],
            globals: []

  def add_section(module, sec_code, section) do
    sections = Map.put(module.sections, sec_code, section)

    Map.put(module, :sections, sections)
  end
end
