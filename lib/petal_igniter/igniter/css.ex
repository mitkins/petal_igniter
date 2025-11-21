defmodule PetalIgniter.Igniter.Css do
  @type directive :: :import | :plugin

  def maybe_add_import(igniter, css_path, import) do
    maybe_add_directive(igniter, css_path, :import, import, nil)
  end

  def maybe_add_plugin(igniter, css_path, plugin) do
    maybe_add_directive(igniter, css_path, :plugin, plugin, :import)
  end

  @spec maybe_add_directive(Igniter.t(), String, directive(), String, directive()) :: Igniter.t()
  def maybe_add_directive(igniter, css_path, directive, value, after_directive) do
    escaped_value = Regex.escape(value)

    igniter
    |> Igniter.update_file(css_path, fn source ->
      content = Rewrite.Source.get(source, :content)

      if String.match?(content, ~r/@#{directive}\s+["']?#{escaped_value}["']?;/) do
        source
      else
        new_content = add_directive(content, directive, value, after_directive)

        Rewrite.Source.update(source, :content, new_content)
      end
    end)
  end

  defp add_directive(content, directive, value, after_directive) do
    directive_statement = "@#{directive} \"#{value}\";"

    # Find all existing @import statements
    directive_regex = ~r/^@#{directive}\s+[^;]+;/m
    directive_matches = Regex.scan(directive_regex, content, return: :index)

    alternative_matches =
      if after_directive && directive_matches == [] do
        after_directive_regex = ~r/^@#{after_directive}\s+[^;]+;/m
        Regex.scan(after_directive_regex, content, return: :index)
      else
        []
      end

    cond do
      directive_matches != [] ->
        # Find the last instance of the directive
        {last_start, last_length} = List.last(directive_matches) |> hd()
        last_end = last_start + last_length

        # Insert after the last instance of the directive
        before_directive = String.slice(content, 0, last_end)
        after_directive = String.slice(content, last_end, String.length(content))

        before_directive <> "\n" <> directive_statement <> after_directive

      alternative_matches != [] ->
        {last_start, last_length} = List.last(alternative_matches) |> hd()
        last_end = last_start + last_length

        # Insert after the last alternative directive
        before_alt_directive = String.slice(content, 0, last_end)
        after_alt_directive = String.slice(content, last_end, String.length(content))

        before_alt_directive <> "\n\n" <> directive_statement <> after_alt_directive

      true ->
        # No existing directive, add at the beginning
        if String.trim(content) == "" do
          directive_statement <> "\n"
        else
          directive_statement <> "\n\n" <> content
        end
    end
  end
end
