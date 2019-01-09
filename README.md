![WaspVM Banner](https://s3-us-west-2.amazonaws.com/elixium-assets/waspban.png)

[![Packagist](https://img.shields.io/badge/license-MIT-blue.svg)]()
[![](https://img.shields.io/hexpm/v/wasp_vm.svg)](https://hex.pm/packages/wasp_vm)
[![Build Status](https://travis-ci.org/ElixiumNetwork/WaspVM.svg?branch=master)](https://travis-ci.org/ElixiumNetwork/WaspVM)

WebAssembly Virtual Machine written in Elixir. Currently used as the Wasm VM in
the [Elixium Network](https://www.elixiumnetwork.org)

## Usage

```elixir
{:ok, ref} = WaspVM.start() # Start WaspVM
WaspVM.load_file(ref, "path/to/wasm/file.wasm") # Load a module
WaspVM.execute(ref, "some_exported_function") # Call a function
# => {:ok, total_gas_cost, :function_return_value}
```

More detailed usage instructions can be found on [HexDocs](https://hexdocs.pm/wasp_vm/0.8.0/WaspVM.html#execute/4-usage).

## Installation

Add `wasp_vm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wasp_vm, "~> 0.7"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/wasp_vm](https://hexdocs.pm/wasp_vm).
