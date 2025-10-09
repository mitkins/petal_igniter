defmodule Mix.Tasks.PetalComponents.Install.Docs do
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
  defmodule Mix.Tasks.PetalComponents.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @components [
      %{module: Loading, file: "loading.ex", test_file: "loading_test.exs"},
      %{module: Link, file: "link.ex", test_file: "link_test.exs"},
      %{module: Icon, file: "icon.ex", test_file: "icon_test.exs"},
      %{module: Button, file: "button.ex", test_file: "button_test.exs"}
    ]

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
        composes: [
          "petal.heroicons.install",
          "petal.tailwind.install",
          "petal_components.css.install"
        ],
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
      component_templates_folder =
        Igniter.Project.Application.priv_dir(igniter, ["templates", "component"])

      test_templates_folder =
        Igniter.Project.Application.priv_dir(igniter, ["templates", "test"])

      base_module =
        if igniter.args.options[:lib] do
          Igniter.Project.Module.module_name_prefix(igniter)
        else
          Igniter.Libs.Phoenix.web_module(igniter)
          |> Module.concat(Components.PetalComponents)
        end

      # Do your work here and return an updated igniter
      igniter
      |> Igniter.Project.Deps.add_dep({:phoenix, "~> 1.7"})
      |> Igniter.Project.Deps.add_dep({:phoenix_live_view, "~> 1.0"})
      |> Igniter.Project.Deps.add_dep({:lazy_html, ">= 0.0.0", only: :test})
      |> Igniter.compose_task("petal.heroicons.install")
      |> Igniter.compose_task("petal.tailwind.install")
      |> Igniter.compose_task("petal_components.css.install")
      |> reduce_into(@components, fn component, igniter ->
        generate_component(
          igniter,
          component_templates_folder,
          base_module,
          component.module,
          component.file
        )
      end)
      |> generate_component_case(test_templates_folder, base_module)
      |> reduce_into(@components, fn component, igniter ->
        generate_test(
          igniter,
          test_templates_folder,
          base_module,
          component.module,
          component.test_file
        )
      end)
    end

    defp reduce_into(igniter, enumerable, fun), do: Enum.reduce(enumerable, igniter, fun)

    defp generate_component(igniter, component_templates_folder, base_module, module_name, file) do
      component_template = Path.join(component_templates_folder, file)
      component_module = Module.concat(base_module, module_name)
      component_path = Igniter.Project.Module.proper_location(igniter, component_module)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(component_template, component_path, module_prefix: module_prefix)
    end

    defp generate_component_case(igniter, test_templates_folder, base_module) do
      test_template = Path.join(test_templates_folder, "_component_case.ex")
      # test_module = Module.concat(base_module, ComponentCase)
      test_path = "test/support/component_case.ex"

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(test_template, test_path, module_prefix: module_prefix)
    end

    defp generate_test(igniter, test_templates_folder, base_module, module_name, file) do
      test_template = Path.join(test_templates_folder, file)
      test_module = Module.concat(base_module, module_name)
      test_path = Igniter.Project.Module.proper_location(igniter, test_module, :test)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(test_template, test_path, module_prefix: module_prefix)
    end
  end
else
  defmodule Mix.Tasks.PetalComponents.Install do
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
