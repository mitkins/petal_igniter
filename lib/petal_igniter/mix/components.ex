defmodule PetalIgniter.Mix.Components do
  @components [
    accordion: [:icon],
    alert: [:icon],
    avatar: [:icon],
    badge: [],
    breadcrumbs: [:icon, :link],
    button: [:icon, :link, :loading],
    button_group: [],
    card: [:avatar, :typography],
    container: [],
    dropdown: [:icon, :link],
    field: [:icon],
    form: [],
    icon: [],
    input: [:icon],
    link: [],
    loading: [],
    marquee: [],
    menu: [:icon, :link],
    modal: [:icon],
    pagination: [:icon, :link, :pagination_internal],
    pagination_internal: [],
    progress: [],
    rating: [],
    skeleton: [],
    slide_over: [],
    stepper: [:icon],
    table: [:avatar],
    tabs: [:link],
    typography: [],
    user_dropdown_menu: [:avatar, :dropdown, :icon]
  ]

  @private [:pagination_internal]

  @skip_tests [:pagination_internal]

  @skip_css [
    :field,
    :icon,
    :input,
    :link,
    :pagination_internal,
    :user_dropdown_menu
  ]

  def validate_component_names(component_names) do
    module_names =
      @components
      |> Enum.map(fn {module_name, _deps} -> module_name end)

    rejected =
      component_names
      |> atomise()
      |> Enum.reject(fn atom_name ->
        atom_name in module_names
      end)

    case rejected do
      [] -> :ok
      _ -> {:error, rejected}
    end
  end

  def dep_names(component_names) do
    @components
    |> filter_by_name(component_names)
    |> Enum.flat_map(fn {_module_name, deps} -> deps end)
    |> Enum.uniq()
  end

  def public_dep_names(component_names) do
    @components
    |> filter_by_name(component_names)
    |> Enum.filter(fn {module_name, _deps} -> !(module_name in @private) end)
    |> Enum.flat_map(fn {_module_name, deps} -> deps end)
    |> Enum.uniq()
  end

  def components(component_names) do
    @components
    |> filter_by_name(component_names)
    |> Enum.map(fn {module_name, _deps} ->
      {PetalIgniter.Igniter.Module.to_module(module_name), elixir_file(module_name)}
    end)
  end

  def public_components(component_names) do
    @components
    |> filter_by_name(component_names)
    |> Enum.filter(fn {module_name, _deps} -> !(module_name in @private) end)
    |> Enum.map(fn {module_name, _deps} ->
      {PetalIgniter.Igniter.Module.to_module(module_name), elixir_file(module_name)}
    end)
  end

  def tests(component_names) do
    @components
    |> filter_by_name(component_names)
    |> Enum.filter(fn {module_name, _file} -> !(module_name in @skip_tests) end)
    |> Enum.map(fn {module_name, _deps} ->
      {
        PetalIgniter.Igniter.Module.to_module(module_name),
        test_file(module_name)
      }
    end)
  end

  def css_files(component_names) do
    @components
    |> filter_by_name(component_names)
    |> Enum.filter(fn {module_name, _file} -> !(module_name in @skip_css) end)
    |> Enum.map(fn {module_name, _deps} ->
      css_file(module_name)
    end)
  end

  defp atomise(component_names) do
    Enum.map(component_names, fn component_name ->
      if is_binary(component_name) do
        component_name
        |> Macro.underscore()
        |> String.to_atom()
      else
        component_name
      end
    end)
  end

  defp filter_by_name(components, []), do: components

  defp filter_by_name(components, component_names) do
    atom_names = atomise(component_names)

    components
    |> Enum.filter(fn {module_name, _deps} ->
      module_name in atom_names
    end)
  end

  defp elixir_file(module) do
    component_name = Atom.to_string(module)

    component_name <> ".ex"
  end

  defp test_file(module) do
    component_name = Atom.to_string(module)

    component_name <> "_test.exs"
  end

  defp css_file(module) do
    component_name = Atom.to_string(module)

    component_name <> ".css"
  end
end
