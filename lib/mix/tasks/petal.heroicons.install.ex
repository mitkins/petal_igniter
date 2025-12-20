defmodule Mix.Tasks.Petal.Heroicons.Install.Docs do
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
  defmodule Mix.Tasks.Petal.Heroicons.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @app_css "assets/css/app.css"

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
      igniter
      |> PetalIgniter.Igniter.Project.Deps.check_and_add_dep(
        {:heroicons,
         [
           github: "tailwindlabs/heroicons",
           tag: "v2.2.0",
           sparse: "optimized",
           app: false,
           compile: false,
           depth: 1
         ]}
      )
      |> then(fn igniter ->
        cond do
          igniter.args.options[:lib] ->
            igniter

          Igniter.exists?(igniter, @app_css) ->
            heroicons_js_template =
              PetalIgniter.Igniter.Project.css_template(igniter, "_tailwind_heroicons.js")

            igniter
            |> Igniter.copy_template(
              heroicons_js_template,
              "assets/css/tailwind_heroicons.js",
              [],
              on_exists: :overwrite
            )
            |> PetalIgniter.Igniter.Css.maybe_add_plugin(@app_css, "./tailwind_heroicons.js")

          true ->
            Igniter.add_warning(igniter, "Could not find #{@app_css}. Skipping CSS imports.")
        end
      end)
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
