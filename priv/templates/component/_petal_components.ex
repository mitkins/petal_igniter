defmodule <%= @module_prefix %>.PetalComponents do
  defmacro __using__(_) do
    quote do
      alias <%= @module_prefix %>.PetalComponents

      <%=
        @components
        |> Enum.map(fn {module, _file_name} ->
          module_name = PetalIgniter.Module.remove_prefix(module)

          "import PetalComponents.#{module_name}\n"
        end)
      %>
    end
  end
end
