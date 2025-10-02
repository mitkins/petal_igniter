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
      |> generate_loading_component(component_templates_folder, base_module)
      |> generate_link_component(component_templates_folder, base_module)
      |> generate_icon_component(component_templates_folder, base_module)
      |> generate_button_component(component_templates_folder, base_module)
      |> generate_component_case(test_templates_folder, base_module)
      |> generate_loading_test(test_templates_folder, base_module)
      |> generate_link_test(test_templates_folder, base_module)
      |> generate_icon_test(test_templates_folder, base_module)
      |> generate_button_test(test_templates_folder, base_module)
    end

    defp generate_loading_component(igniter, component_templates_folder, base_module) do
      component_template = Path.join(component_templates_folder, "loading.ex")
      component_module = Module.concat(base_module, Loading)
      component_path = Igniter.Project.Module.proper_location(igniter, component_module)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(component_template, component_path, module_prefix: module_prefix)
    end

    defp generate_link_component(igniter, component_templates_folder, base_module) do
      component_template = Path.join(component_templates_folder, "link.ex")
      component_module = Module.concat(base_module, Link)
      component_path = Igniter.Project.Module.proper_location(igniter, component_module)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(component_template, component_path, module_prefix: module_prefix)
    end

    defp generate_icon_component(igniter, component_templates_folder, base_module) do
      component_template = Path.join(component_templates_folder, "icon.ex")
      component_module = Module.concat(base_module, Icon)
      component_path = Igniter.Project.Module.proper_location(igniter, component_module)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(component_template, component_path, module_prefix: module_prefix)
    end

    defp generate_button_component(igniter, component_templates_folder, base_module) do
      component_template = Path.join(component_templates_folder, "button.ex")
      component_module = Module.concat(base_module, Button)
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

    defp generate_loading_test(igniter, test_templates_folder, base_module) do
      test_template = Path.join(test_templates_folder, "loading_test.exs")
      test_module = Module.concat(base_module, LoadingTest)
      test_path = Igniter.Project.Module.proper_location(igniter, test_module, :test)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(test_template, test_path, module_prefix: module_prefix)
    end

    defp generate_link_test(igniter, test_templates_folder, base_module) do
      test_template = Path.join(test_templates_folder, "link_test.exs")
      test_module = Module.concat(base_module, LinkTest)
      test_path = Igniter.Project.Module.proper_location(igniter, test_module, :test)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(test_template, test_path, module_prefix: module_prefix)
    end

    defp generate_icon_test(igniter, test_templates_folder, base_module) do
      test_template = Path.join(test_templates_folder, "icon_test.exs")
      test_module = Module.concat(base_module, IconTest)
      test_path = Igniter.Project.Module.proper_location(igniter, test_module, :test)

      # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
      module_prefix =
        base_module
        |> Module.split()
        |> Enum.join(".")

      igniter
      |> Igniter.copy_template(test_template, test_path, module_prefix: module_prefix)
    end

    defp generate_button_test(igniter, test_templates_folder, base_module) do
      test_template = Path.join(test_templates_folder, "button_test.exs")
      test_module = Module.concat(base_module, ButtonTest)
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
