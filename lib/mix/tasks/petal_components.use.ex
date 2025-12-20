defmodule Mix.Tasks.PetalComponents.Use.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Add Petal Components to your web module"
  end

  @spec example() :: String.t()
  def example do
    "mix petal_components.use"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Adds the Petal Components module to your web module's html_helpers/0
    function, making all public components available throughout your
    application. This task updates your web module to use the PetalComponents
    module and optionally filters which components are included.

    ## Example

    ```sh
    #{example()}
    ```

    To include only specific components:

    ```sh
    mix petal_components.use --component button --component dropdown
    ```

    Using the short alias:

    ```sh
    mix petal_components.use -c button -c dropdown
    ```

    ## Options

    * `--component` or `-c` - Specify component(s) to include (can be used multiple times)
    * `--lib` - Skip updating the web module (useful when components are in lib)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PetalComponents.Use do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task
    require Igniter.Code.Common

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :petal_igniter,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [lib: :boolean, component: :keep],
        # Default values for the options in the `schema`
        defaults: [component: []],
        # CLI aliases
        aliases: [c: :component],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      # Do your work here and return an updated igniter
      if igniter.args.options[:lib] do
        igniter
      else
        web_module_use(igniter)
      end
    end

    defp web_module_use(igniter) do
      component_names = igniter.args.options[:component]

      with :ok <- PetalIgniter.Mix.Components.validate_component_names(component_names) do
        public_components = PetalIgniter.Mix.Components.public_components(component_names)

        public_deps =
          PetalIgniter.Mix.Components.public_dep_names(component_names)
          |> PetalIgniter.Mix.Components.public_components()

        public_components =
          if igniter.args.options[:no_deps] do
            public_components
          else
            Enum.uniq(public_components ++ public_deps)
          end

        web_module = Igniter.Libs.Phoenix.web_module(igniter)
        components_module = Module.concat(web_module, Components)
        petal_module = Module.concat(web_module, Components.PetalComponents)
        module_prefix = PetalIgniter.Igniter.Module.remove_prefix(components_module)

        petal_components_template =
          PetalIgniter.Igniter.Project.component_template(igniter, "_petal_components.ex")

        petal_components_file = Igniter.Project.Module.proper_location(igniter, petal_module)

        igniter
        |> Igniter.copy_template(petal_components_template, petal_components_file,
          module_prefix: module_prefix,
          components: public_components
        )
        |> add_petal_components_use(web_module, petal_module)
      else
        {:error, rejected} ->
          PetalIgniter.Igniter.Templates.add_issues_for_rejected_components(igniter, rejected)
      end
    end

    defp add_petal_components_use(igniter, web_module, petal_module) do
      {exists, igniter} = Igniter.Project.Module.module_exists(igniter, web_module)

      if exists do
        igniter
        |> Igniter.Project.Module.find_and_update_module!(
          web_module,
          &update_html_helpers(&1, petal_module)
        )
      else
        Igniter.add_warning(
          igniter,
          "Web module #{web_module} does not exist. Skipping update to html_helpers."
        )
      end
    end

    defp update_html_helpers(zipper, petal_module) do
      with {:ok, zipper} <- Igniter.Code.Function.move_to_defp(zipper, :html_helpers, 0),
           {:ok, block_zipper} <- Igniter.Code.Common.move_to_do_block(zipper),
           {:ok, _found_zipper} <- find_petal_use(zipper, petal_module) do
        {:ok, block_zipper}
      else
        {:error, :not_found} ->
          inject_petal_use(zipper, petal_module)

        :error ->
          {:error, "Could not find html_helpers/0 function in #{inspect(petal_module)}"}
      end
    end

    defp find_petal_use(zipper, petal_module) do
      # Look for import <module> within the current scope
      case Igniter.Code.Common.move_to(zipper, fn z ->
             case Sourceror.Zipper.node(z) do
               {{:., _, [:use]}, _, [{:__aliases__, _, module_parts}]} ->
                 # Convert module atom to list (e.g., PetalComponents -> [:PetalComponents])
                 expected_parts = petal_module |> Module.split() |> Enum.map(&String.to_atom/1)
                 module_parts == expected_parts

               _ ->
                 false
             end
           end) do
        {:ok, zipper} -> {:ok, zipper}
        :error -> {:error, :not_found}
      end
    end

    defp inject_petal_use(zipper, petal_module) do
      with {:ok, zipper} <- Igniter.Code.Function.move_to_defp(zipper, :html_helpers, 0),
           {:ok, quote_zipper} <- Igniter.Code.Common.move_to_do_block(zipper),
           quote_node <- Sourceror.Zipper.node(quote_zipper) do
        # This code checks for direct child references to `use xxx`. It avoids dipping into
        # the unquoted code (where yet more refenres to `use` exist)
        use_calls =
          case quote_node do
            {:__block__, _, children} ->
              children
              |> Enum.with_index()
              |> Enum.filter(fn {child, _idx} -> match?({:use, _, _}, child) end)
              |> Enum.map(fn {_child, idx} ->
                # Start at first child, then move right idx times
                zipper = Sourceror.Zipper.down(quote_zipper)

                for _ <- 1..idx, reduce: zipper do
                  acc_zipper -> Sourceror.Zipper.right(acc_zipper)
                end
              end)

            _ ->
              []
          end

        new_code =
          """
          # Add Petal Components
          use #{PetalIgniter.Igniter.Module.remove_prefix(petal_module)}
          """

        zipper =
          case use_calls do
            [] ->
              Igniter.Code.Common.add_code(quote_zipper, new_code, placement: :before)

            _ ->
              last_use = List.last(use_calls)
              Igniter.Code.Common.add_code(last_use, new_code, placement: :after)
          end

        {:ok, zipper}
      end
    end
  end
else
  defmodule Mix.Tasks.Petal.Heroicons.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'petal_components.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
