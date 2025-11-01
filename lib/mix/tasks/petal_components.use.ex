defmodule Mix.Tasks.PetalComponents.Use.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "A short description of your task"
  end

  @spec example() :: String.t()
  def example do
    "mix petal_components.install --example arg"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Longer explanation of your task

    ## Example

    ```sh
    #{example()}
    ```

    ## Options

    * `--example-option` or `-e` - Docs for your option
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
        schema: [lib: :boolean],
        # Default values for the options in the `schema`
        defaults: [],
        # CLI aliases
        aliases: [],
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
        component_templates_folder =
          Igniter.Project.Application.priv_dir(igniter, ["templates", "component"])

        public_components = PetalIgniter.Components.public_components()

        web_module = Igniter.Libs.Phoenix.web_module(igniter)
        components_module = Module.concat(web_module, Components)
        petal_module = Module.concat(web_module, Components.PetalComponents)

        petal_components_template = Path.join(component_templates_folder, "_petal_components.ex")
        petal_components_file = Igniter.Project.Module.proper_location(igniter, petal_module)
        module_prefix = PetalIgniter.Templates.remove_prefix(components_module)

        igniter
        |> Igniter.copy_template(petal_components_template, petal_components_file,
          module_prefix: module_prefix,
          components: public_components
        )
        |> add_petal_components_use(web_module, petal_module)
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
           {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper),
           {:ok, zipper} <- move_to_gettext_use(zipper) do
        petal_module_name =
          petal_module
          |> Module.split()
          |> Enum.join(".")

        zipper =
          zipper
          |> Igniter.Code.Common.add_code(
            """
            use #{petal_module_name}
            """,
            placement: :before
          )

        {:ok, zipper}
      end
    end

    defp move_to_gettext_use(zipper) do
      Igniter.Code.Common.move_to_pattern(zipper, {:use, _, [{:__aliases__, _, [:Gettext]}, _]})
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
