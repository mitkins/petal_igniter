defmodule PetalIgniter.Igniter.Templates do
  def reduce_into(igniter, enumerable, fun), do: Enum.reduce(enumerable, igniter, fun)

  def add_warnings_for_missing_deps(igniter, base_module, deps) do
    deps
    |> Enum.reduce(igniter, fn {module, _file}, acc_igniter ->
      component_file =
        PetalIgniter.Igniter.Module.proper_location(acc_igniter, base_module, module)

      if !Igniter.exists?(acc_igniter, component_file) do
        Igniter.add_warning(
          acc_igniter,
          "Missing dependency #{component_file}"
        )
      else
        acc_igniter
      end
    end)
  end

  def add_issues_for_rejected_components(igniter, rejected) do
    rejected
    |> Enum.reduce(igniter, fn rejected_component_name, acc_igniter ->
      Igniter.add_issue(
        acc_igniter,
        "'#{rejected_component_name}' is not a valid component name"
      )
    end)
  end
end
