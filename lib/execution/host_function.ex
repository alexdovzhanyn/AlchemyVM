defmodule AlchemyVM.HostFunction do

  @moduledoc """
    Exposes a DSL for defining and importing host functions
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import AlchemyVM.HostFunction

      @before_compile AlchemyVM.HostFunction

      Module.register_attribute(__MODULE__, :host_funcs, accumulate: true)
    end
  end

  @doc """
    Defines a host function that can be passed in to the VM using `create_imports/1`

    Will use the name of the module that it's defined in as the name of the
    corresponding WebAssembly module that this host function can be imported from.
    `fname` can be a string or an atom. A variable called `ctx` is available
    within the context of the macro body as a pointer to VM state, to be used
    with functions defined in `AlchemyVM.HostFunction.API`.

  ## Usage

  Create an Elixir module that will be used to import host functions into
  WebAssembly:

      defmodule Math do
        use AlchemyVM.HostFunction

        defhost add(a, b) do
          a + b
        end
      end

  Somewhere in your app:

      defmodule MyWaspApp do
        def start do
          {:ok, pid} = AlchemyVM.start()

          imports = AlchemyVM.HostFunction.create_imports(Math)

          AlchemyVM.load_file(pid, "path/to/wasm/file.wasm", imports)
        end
      end

  In the above "path/to/wasm/file.wasm", the host function can now be imported:

      (import "Math" "add" (func (param i32 i32) (result i32)))

  Note that the Elixir module name was used to define the WebAssembly module name
  that's being used for the import.
  """
  defmacro defhost(head, do: block) do
    {fname, args} = Macro.decompose_call(head)
    name = to_string(fname)

    quote generated: true do
      def hostfunc(unquote(name), unquote(args), var!(ctx)), do: unquote(block)

      Module.put_attribute(__MODULE__, :host_funcs, unquote(name))
    end
  end

  @doc """
    Pass in an Elixir module or list of Elixir modules that implement `defhost`
    calls to generate imports for WebAssembly to be passed in when loading a
    WebAssembly module into the VM

  ## Usage

  When using a single module to define imports:

      AlchemyVM.HostFunction.create_imports(Module1)

  Functions will be accessible in the WebAssembly module as:

      (import "Module1" "function_name")

  When using multiple modules to define imports:

      AlchemyVM.HostFunction.create_imports([Module1, Module2, Module3])

  Functions will be accessible in the WebAssembly module as:

      (import "Module1" "function_name")
      (import "Module2" "function_name")
      (import "Module3" "function_name")
  """
  @spec create_imports(list | atom) :: map
  def create_imports(modules) when is_list(modules) do
    Enum.reduce(modules, %{}, fn mod, acc ->
      "Elixir." <> mod_string = to_string(mod)
      Map.put(acc, mod_string, create_import(mod))
    end)
  end

  def create_imports(module), do: create_imports([module])

  defp create_import(module) do
    module
    |> apply(:hostfuncs, [])
    |> Enum.reduce(%{}, fn fname, acc ->
      Map.put(acc, fname, fn ctx, args -> apply(module, :hostfunc, [fname, args, ctx]) end)
    end)
  end

  defmacro __before_compile__(_env) do
    quote do
      def hostfuncs, do: @host_funcs
    end
  end
end
