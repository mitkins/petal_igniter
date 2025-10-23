defmodule Mix.Tasks.PetalComponents.Css.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "A short description of your task"
  end

  @spec example() :: String.t()
  def example do
    "mix petal_components.css.install --example arg"
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

    @app_css "assets/css/app.css"

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
      colors_css_template = Path.join(css_templates_folder, "_colors.css")

      css_files =
        PetalIgniter.Components.css_files()
        |> Enum.map(fn css_file ->
          css_template = Path.join(css_templates_folder, css_file)

          EEx.eval_file(css_template, [])
        end)

      # Do your work here and return an updated igniter
      if igniter.args.options[:lib] do
        igniter
        |> Igniter.copy_template(default_css_template, "assets/css/default.css",
          css_files: css_files
        )
      else
        igniter
        |> Igniter.copy_template(default_css_template, "assets/css/petal_components.css",
          css_files: css_files
        )
        |> Igniter.copy_template(colors_css_template, "assets/css/colors.css", [])
        |> then(fn igniter ->
          if Igniter.exists?(igniter, @app_css) do
            igniter
            |> maybe_add_import(@app_css, "./petal_components.css")
            |> maybe_add_import(@app_css, "./colors.css")
          else
            Igniter.add_warning(igniter, "Could not find #{@app_css}. Skipping CSS imports.")
          end
        end)
      end
    end

    defp maybe_add_import(igniter, css_path, import) do
      escaped_import = Regex.escape(import)

      igniter
      |> Igniter.update_file(css_path, fn source ->
        content = Rewrite.Source.get(source, :content)

        if String.match?(content, ~r/@import\s+["']?#{escaped_import}["']?;/) do
          source
        else
          new_content = add_import(content, import)

          Rewrite.Source.update(source, :content, new_content)
        end
      end)
    end

    defp add_import(content, import) do
      import_statement = "@import \"#{import}\";"

      # Find all existing @import statements
      import_regex = ~r/^@import\s+[^;]+;/m

      case Regex.run(import_regex, content, return: :index) do
        nil ->
          # No existing imports, add at the beginning
          if String.trim(content) == "" do
            import_statement <> "\n"
          else
            import_statement <> "\n\n" <> content
          end

        _ ->
          # Find the last import statement
          matches = Regex.scan(import_regex, content, return: :index)
          {last_start, last_length} = List.last(matches) |> hd()
          last_end = last_start + last_length

          # Insert after the last import
          before_import = String.slice(content, 0, last_end)
          after_import = String.slice(content, last_end, String.length(content))

          before_import <> "\n" <> import_statement <> after_import
      end
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
