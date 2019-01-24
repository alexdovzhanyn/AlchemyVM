defmodule WaspVM.HostFunction do

  @moduledoc """
    Exposes a DSL for defining and importing host functions
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import WaspVM.HostFunction

      @before_compile WaspVM.HostFunction

      Module.register_attribute(__MODULE__, :host_funcs, accumulate: true)
    end
  end

  @doc """
    Defines a host function that can be passed in to the VM using `create_imports/1`

    Will use the name of the module that it's defined in as the name of the
    corresponding WebAssembly module that this host function can be imported from.
    `fname` can be a string or an atom. A variable called `ctx` is available
    within the context of the macro body as a pointer to VM state, to be used
    with functions defined in `WaspVM.HostFunction.API`.

  ## Usage

  Create an Elixir module that will be used to import host functions into
  WebAssembly:

      defmodule Math do
        use WaspVM.HostFunction

        defhost add(a, b) do
          a + b
        end
      end

  Somewhere in your app:

      defmodule MyWaspApp do
        def start do
          {:ok, pid} = WaspVM.start()

          imports = WaspVM.HostFunction.create_imports(Math)

          WaspVM.load_file(pid, "path/to/wasm/file.wasm", imports)
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
