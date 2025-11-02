defmodule PetalIgniter.Module do
  @type location_type :: :source_folder | {:source_folder, String.t()} | :test | :test_support

  @spec proper_location(Igniter.t(), module(), module(), location_type()) :: String.t()
  def proper_location(igniter, base_module, module_name, type \\ :source_folder) do
    module = Module.concat(base_module, module_name)
    Igniter.Project.Module.proper_location(igniter, module, type)
  end

  @spec remove_prefix(module()) :: String.t()
  def remove_prefix(base_module) do
    # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
    base_module
    |> Module.split()
    |> Enum.join(".")
  end

  @spec to_module(module()) :: module()
  def to_module(module_name) when is_atom(module_name) do
    module_name
    |> Atom.to_string()
    |> Macro.camelize()
    |> then(&Module.concat([Elixir, &1]))
  end
end
