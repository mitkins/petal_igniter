defmodule Mix.Tasks.PetalComponents.Test.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generate test files for Petal Components"
  end

  @spec example() :: String.t()
  def example do
    "mix petal_components.test"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Generates test files for Petal Components in your test directory. You can
    optionally specify which components to generate tests for using the
    --component flag. If no components are specified, tests for all available
    components will be generated. This task also creates a ComponentCase
    support module for testing components.

    ## Example

    ```sh
    #{example()}
    ```

    Generate tests for specific components:

    ```sh
    mix petal_components.test --component button --component dropdown
    ```

    Using the short alias:

    ```sh
    mix petal_components.test -c button -c dropdown
    ```

    ## Options

    * `--component` or `-c` - Specify component(s) to generate tests for (can be used multiple times)
    * `--lib` - Generate tests in lib instead of web (useful for library projects)
    * `--no-deps` - Skip generating tests for component dependencies
    * `--js-lib` - JavaScript library to use (default: alpine_js)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PetalComponents.Test do
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
        composes: [],
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
        component_case_template =
          PetalIgniter.Igniter.Project.test_template(igniter, "_component_case.ex")

        base_module =
          if igniter.args.options[:lib] do
            Igniter.Project.Module.module_name_prefix(igniter)
          else
            Igniter.Libs.Phoenix.web_module(igniter)
            |> Module.concat(Components.PetalComponents)
          end

        module_prefix = PetalIgniter.Igniter.Module.remove_prefix(base_module)

        tests = PetalIgniter.Mix.Components.tests(component_names)

        deps =
          PetalIgniter.Mix.Components.dep_names(component_names)
          |> PetalIgniter.Mix.Components.tests()

        tests =
          if igniter.args.options[:no_deps] do
            tests
          else
            Enum.uniq(tests ++ deps)
          end

        valid_js_lib = PetalIgniter.Igniter.Templates.valid_js_lib(igniter.args.options[:js_lib])

        igniter
        |> PetalIgniter.Igniter.Templates.add_warning_for_invalid_js_lib(
          igniter.args.options[:js_lib] != valid_js_lib
        )
        |> Igniter.copy_template(
          component_case_template,
          "test/support/component_case.ex",
          [module_prefix: module_prefix],
          on_exists: :overwrite
        )
        |> PetalIgniter.Igniter.Templates.reduce_into(tests, fn {module, test_file}, igniter ->
          test_template = PetalIgniter.Igniter.Project.test_template(igniter, test_file)

          test_file =
            PetalIgniter.Igniter.Module.proper_location(igniter, base_module, module, :test)

          igniter
          |> Igniter.copy_template(
            test_template,
            test_file,
            [module_prefix: module_prefix, js_lib: valid_js_lib],
            on_exists: :overwrite
          )
        end)
        |> PetalIgniter.Igniter.Templates.add_warnings_for_missing_deps(base_module, deps, :test)
      else
        {:error, rejected} ->
          PetalIgniter.Igniter.Templates.add_issues_for_rejected_components(igniter, rejected)
      end
    end
  end
else
  defmodule Mix.Tasks.PetalComponents.Test do
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
