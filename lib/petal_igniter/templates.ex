defmodule PetalIgniter.Templates do
  def reduce_into(igniter, enumerable, fun), do: Enum.reduce(enumerable, igniter, fun)

  def remove_prefix(base_module) do
    # Seems cleaner than Atom.to_string(base_nodule) |> String.replace("Elixir.", "")
    base_module
    |> Module.split()
    |> Enum.join(".")
  end
end
