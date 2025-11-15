defmodule Mix.Tasks.PetalComponents.Test.Install.Docs do
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
  defmodule Mix.Tasks.PetalComponents.Test.Install do
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
        schema: [lib: :boolean, js_lib: :string, component: :keep],
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
        templates_folder =
          Igniter.Project.Application.priv_dir(igniter, ["templates", "test"])

        component_case_template = Path.join(templates_folder, "_component_case.ex")

        base_module =
          if igniter.args.options[:lib] do
            Igniter.Project.Module.module_name_prefix(igniter)
          else
            Igniter.Libs.Phoenix.web_module(igniter)
            |> Module.concat(Components.PetalComponents)
          end

        module_prefix = PetalIgniter.Igniter.Module.remove_prefix(base_module)

        tests = PetalIgniter.Mix.Components.tests(component_names)

        # Do your work here and return an updated igniter
        igniter
        |> Igniter.copy_template(
          component_case_template,
          "test/support/component_case.ex",
          [module_prefix: module_prefix],
          on_exists: :overwrite
        )
        |> PetalIgniter.Igniter.Templates.reduce_into(tests, fn {module, test_file}, igniter ->
          test_template = Path.join(templates_folder, test_file)

          test_file =
            PetalIgniter.Igniter.Module.proper_location(igniter, base_module, module, :test)

          igniter
          |> Igniter.copy_template(
            test_template,
            test_file,
            [module_prefix: module_prefix, js_lib: igniter.args.options[:js_lib]],
            on_exists: :overwrite
          )
        end)
      else
        {:error, rejected} ->
          PetalIgniter.Igniter.Templates.add_issues_for_rejected_components(igniter, rejected)
      end
    end
  end
else
  defmodule Mix.Tasks.PetalComponents.Test.Install do
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
