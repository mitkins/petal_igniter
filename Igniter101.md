# Interpolate template files

# Get priv folder

# Get web module file

```elixir
web_module_name = Igniter.Libs.Phoenix.web_module(igniter)
module_location = Igniter.Project.Module.proper_location(igniter, web_module_name)
```

# Get web module folder

# Example for --lib switch:

```elixir
# `OptionParser` schema
schema: [lib: :boolean],
# Default values for the options in the `schema`
defaults: [lib: false],
```

# Assets folder is just static

E.g:

```elixir
css_path = "assets/css/default.css"
```
