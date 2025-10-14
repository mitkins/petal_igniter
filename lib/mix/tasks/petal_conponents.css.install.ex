defmodule Mix.Tasks.PetalComponents.Css.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "A short description of your task"
  end

  @spec example() :: String.t()
  def example do
    "mix petal_css.install --example arg"
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
  defmodule Mix.Tasks.PetalComponents.Css.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    @marker "/* Igniter: Components */"

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
      css_templates_folder =
        Igniter.Project.Application.priv_dir(igniter, ["templates", "css"])

      default_css_template = Path.join(css_templates_folder, "_default.css")

      default_css_path =
        if igniter.args.options[:lib] do
          "assets/css/default.css"
        else
          "assets/css/petal_components.css"
        end

      css_files = PetalIgniter.Components.css_files()

      # Do your work here and return an updated igniter
      igniter
      |> then(fn igniter ->
        if igniter.args.options[:lib] do
          igniter
        else
          colors_css_template = Path.join(css_templates_folder, "_colors.css")
          colors_css_path = "assets/css/colors.css"

          Igniter.copy_template(igniter, colors_css_template, colors_css_path, nil)
        end
      end)
      |> Igniter.copy_template(default_css_template, default_css_path, nil)
      |> reduce_into(css_files, fn css_file, igniter ->
        generate_css(igniter, css_templates_folder, default_css_path, css_file)
      end)
      |> remove_marker_from_css_file(default_css_path, @marker)
    end

    defp reduce_into(igniter, enumerable, fun), do: Enum.reduce(enumerable, igniter, fun)

    defp inject_into_css_file(igniter, css_path, marker, content) do
      igniter
      |> Igniter.update_file(css_path, fn source ->
        existing_content = Rewrite.Source.get(source, :content)

        escaped_marker = Regex.escape(marker)

        marker_line =
          case Regex.run(~r/^.*#{escaped_marker}.*$/m, existing_content) do
            [line] -> line
            nil -> ""
          end

        indentation =
          case Regex.run(~r/^(\s*)/, marker_line, capture: :all_but_first) do
            [indentation] -> indentation
            _ -> ""
          end

        indented_content = String.replace(content, ~r/^/m, indentation)

        # Replace the first instance of the marker with content and another marker
        new_content =
          String.replace(existing_content, marker_line, indented_content <> marker_line,
            global: false
          )

        Rewrite.Source.update(source, :content, new_content)
      end)
    end

    defp remove_marker_from_css_file(igniter, css_path, marker) do
      igniter
      |> Igniter.update_file(css_path, fn source ->
        existing_content = Rewrite.Source.get(source, :content)

        escaped_marker = Regex.escape(marker)

        marker_line =
          case Regex.run(~r/^.*#{escaped_marker}.*$/m, existing_content) do
            [line] -> line
            nil -> ""
          end

        escaped_marker_line = Regex.escape(marker_line)

        new_content =
          String.replace(existing_content, ~r/#{escaped_marker_line}\r?\n?/m, "", global: false)

        Rewrite.Source.update(source, :content, new_content)
      end)
    end

    defp generate_css(igniter, css_templates_folder, css_path, css_file) do
      css_template = Path.join(css_templates_folder, css_file)
      css_content = EEx.eval_file(css_template, [])

      inject_into_css_file(igniter, css_path, @marker, css_content)
    end
  end
else
  defmodule Mix.Tasks.PetalComponents.Css.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'petal_css.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
