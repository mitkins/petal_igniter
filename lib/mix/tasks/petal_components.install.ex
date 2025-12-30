defmodule Mix.Tasks.PetalComponents.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Install Petal Components into your Phoenix project"
  end

  @spec example() :: String.t()
  def example do
    "mix petal_components.install"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Installs Petal Components and their dependencies into your Phoenix project.

    This task handles the complete setup process, including installing Heroicons,
    configuring Tailwind CSS, generating CSS files, creating tests and
    copying/integrating component files to your project.

    You can optionally specify which components to install using the --component flag.
    If no components are specified, all available components will be installed.

    ## Example

    ```sh
    #{example()}
    ```

    Install specific components:

    ```sh
    mix petal_components.install --component button --component dropdown
    ```

    Using the short alias:

    ```sh
    mix petal_components.install -c button -c dropdown
    ```

    ## Options

    * `--component` or `-c` - Specify component(s) to install (can be used multiple times)
    * `--lib` - Install components in lib instead of web (useful for library projects)
    * `--js-lib` - JavaScript library to use (default: alpine_js)
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
          "petal_components.css",
          "petal_components.test"
        ],
        # `OptionParser` schema
        schema: [lib: :boolean, no_deps: :boolean, js_lib: :string, component: :keep],
        # Default values for the options in the `schema`
        defaults: [js_lib: "alpine_js", component: []],
        # CLI aliases
        aliases: [c: :component],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      component_names = igniter.args.options[:component]

      with :ok <- PetalIgniter.Mix.Components.validate_component_names(component_names) do
        petal_module =
          if igniter.args.options[:lib] do
            Igniter.Project.Module.module_name_prefix(igniter)
          else
            web_module = Igniter.Libs.Phoenix.web_module(igniter)
            Module.concat(web_module, Components.PetalComponents)
          end

        module_prefix = PetalIgniter.Igniter.Module.remove_prefix(petal_module)

        helpers_template = PetalIgniter.Igniter.Project.component_template(igniter, "_helpers.ex")
        helpers_file = PetalIgniter.Igniter.Module.proper_location(igniter, petal_module, Helpers)

        components = PetalIgniter.Mix.Components.components(component_names)

        deps =
          PetalIgniter.Mix.Components.dep_names(component_names)
          |> PetalIgniter.Mix.Components.components()

        components =
          if igniter.args.options[:no_deps] do
            components
          else
            Enum.uniq(components ++ deps)
          end

        valid_js_lib = PetalIgniter.Igniter.Templates.valid_js_lib(igniter.args.options[:js_lib])

        igniter
        |> PetalIgniter.Igniter.Templates.add_warning_for_invalid_js_lib(
          igniter.args.options[:js_lib] != valid_js_lib
        )
        |> PetalIgniter.Igniter.Project.Deps.check_and_add_dep({:phoenix_live_view, "~> 1.1"})
        |> PetalIgniter.Igniter.Project.Deps.check_and_add_dep({:phoenix_ecto, "~> 4.4"})
        |> PetalIgniter.Igniter.Project.Deps.check_and_add_dep({:phoenix_html_helpers, "~> 1.0"})
        |> Igniter.Project.Deps.add_dep({:lazy_html, ">= 0.0.0", only: :test})
        |> Igniter.compose_task("petal.heroicons.install")
        |> Igniter.compose_task("petal.tailwind.install")
        |> Igniter.compose_task("petal_components.css")
        |> Igniter.copy_template(helpers_template, helpers_file, [module_prefix: module_prefix],
          on_exists: :overwrite
        )
        |> PetalIgniter.Igniter.Templates.reduce_into(
          components,
          fn {module, file}, acc_igniter ->
            component_template =
              PetalIgniter.Igniter.Project.component_template(acc_igniter, file)

            component_file =
              PetalIgniter.Igniter.Module.proper_location(acc_igniter, petal_module, module)

            acc_igniter
            |> Igniter.copy_template(
              component_template,
              component_file,
              [module_prefix: module_prefix, js_lib: valid_js_lib],
              on_exists: :overwrite
            )
          end
        )
        |> Igniter.compose_task("petal_components.use")
        |> Igniter.compose_task("petal_components.test")
        |> PetalIgniter.Igniter.Templates.add_warnings_for_missing_deps(petal_module, deps)
      else
        {:error, rejected} ->
          PetalIgniter.Igniter.Templates.add_issues_for_rejected_components(igniter, rejected)
      end
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
