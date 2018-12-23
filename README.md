![WaspVM Banner](https://s3-us-west-2.amazonaws.com/elixium-assets/waspban.png)

[![Build Status](https://travis-ci.org/ElixiumNetwork/WaspVM.svg?branch=master)](https://travis-ci.org/ElixiumNetwork/WaspVM)

WebAssembly Virtual Machine written in Elixir. Currently used as the Wasm VM in
the [Elixium Network](https://www.elixiumnetwork.org)

## Usage

```elixir
{:ok, ref} = WaspVM.start() # Start WaspVM
WaspVM.load_file(ref, "path/to/wasm/file.wasm") # Load a module
WaspVM.execute(ref, "some_exported_function") # Call a function
# => {:ok, :function_return_value}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `wasp_vm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wasp_vm, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/wasp_vm](https://hexdocs.pm/wasp_vm).
