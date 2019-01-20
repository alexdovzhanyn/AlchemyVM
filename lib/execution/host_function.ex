defmodule WaspVM.HostFunction do

  @doc false
  defmacro __using__(_opts) do
    quote do
      import WaspVM.HostFunction

      @before_compile WaspVM.HostFunction

      Module.register_attribute(__MODULE__, :host_funcs, accumulate: true)
    end
  end

  defmacro defhost(fname, do: block) do
    quote do
      WaspVM.HostFunction.defhost(unquote(fname), []) do
        unquote(block)
      end
    end
  end

  defmacro defhost(fname, args, do: block) when is_atom(fname) do
    name = to_string(fname)

    quote do
      WaspVM.HostFunction.defhost(unquote(name), unquote(args)) do
        unquote(block)
      end
    end
  end

  defmacro defhost(fname, args, do: block) do
    quote generated: true do
      def hostfunc(unquote(fname), unquote(args), var!(ctx)), do: unquote(block)

      Module.put_attribute(__MODULE__, :host_funcs, unquote(fname))
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
