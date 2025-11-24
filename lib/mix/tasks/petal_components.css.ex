defmodule Mix.Tasks.PetalComponents.Css.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "A short description of your task"
  end

  @spec example() :: String.t()
  def example do
    "mix petal_components.css --example arg"
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
  defmodule Mix.Tasks.PetalComponents.Css do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    @app_css "assets/css/app.css"
    @css_folder "assets/css"

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
        schema: [lib: :boolean, no_deps: :boolean, component: :keep],
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
      component_names = igniter.args.options[:component]

      with :ok <- PetalIgniter.Mix.Components.validate_component_names(component_names) do
        css_files = PetalIgniter.Mix.Components.css_files(component_names)

        deps =
          PetalIgniter.Mix.Components.dep_names(component_names)
          |> PetalIgniter.Mix.Components.css_files()

        css_files =
          if igniter.args.options[:no_deps] do
            css_files
          else
            Enum.uniq(css_files ++ deps)
          end

        # Do your work here and return an updated igniter
        if igniter.args.options[:lib] do
          library_css(igniter, css_files)
        else
          web_module_css(igniter, css_files)
        end
        |> PetalIgniter.Igniter.Templates.add_warnings_for_missing_css(
          Path.join(@css_folder, "petal_components"),
          deps
        )
      else
        {:error, rejected} ->
          PetalIgniter.Igniter.Templates.add_issues_for_rejected_components(igniter, rejected)
      end
    end

    defp library_css(igniter, css_files) do
      default_css_template = PetalIgniter.Igniter.Project.css_template(igniter, "_default.css")

      igniter
      |> PetalIgniter.Igniter.Templates.reduce_into(css_files, fn css_file, acc_igniter ->
        css_template = PetalIgniter.Igniter.Project.css_template(igniter, css_file)

        css_file =
          @css_folder
          |> Path.join("petal_components")
          |> Path.join(css_file)

        acc_igniter
        |> Igniter.copy_template(css_template, css_file, [], on_exists: :overwrite)
      end)
      |> Igniter.copy_template(
        default_css_template,
        "assets/css/default.css",
        [css_files: css_files],
        on_exists: :overwrite
      )
    end

    defp web_module_css(igniter, css_files) do
      default_css_template = PetalIgniter.Igniter.Project.css_template(igniter, "_default.css")
      colors_css_template = PetalIgniter.Igniter.Project.css_template(igniter, "_colors.css")

      igniter
      |> PetalIgniter.Igniter.Templates.reduce_into(css_files, fn css_file, acc_igniter ->
        css_template = PetalIgniter.Igniter.Project.css_template(igniter, css_file)

        css_file =
          @css_folder
          |> Path.join("petal_components")
          |> Path.join(css_file)

        acc_igniter
        |> Igniter.copy_template(css_template, css_file, [], on_exists: :overwrite)
      end)
      |> Igniter.copy_template(
        default_css_template,
        "assets/css/petal_components.css",
        [css_files: css_files],
        on_exists: :overwrite
      )
      |> Igniter.copy_template(colors_css_template, "assets/css/colors.css", [],
        on_exists: :overwrite
      )
      |> then(fn igniter ->
        if Igniter.exists?(igniter, @app_css) do
          igniter
          |> PetalIgniter.Igniter.Css.maybe_add_import(@app_css, "./petal_components.css")
          |> PetalIgniter.Igniter.Css.maybe_add_import(@app_css, "./colors.css")
          |> PetalIgniter.Igniter.Css.maybe_add_plugin(@app_css, "@tailwindcss/typography")
          |> PetalIgniter.Igniter.Css.maybe_add_plugin(@app_css, "@tailwindcss/forms")
        else
          Igniter.add_warning(igniter, "Could not find #{@app_css}. Skipping CSS imports.")
        end
      end)
    end
  end
else
  defmodule Mix.Tasks.PetalComponents.Css do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'petal_components.css' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
