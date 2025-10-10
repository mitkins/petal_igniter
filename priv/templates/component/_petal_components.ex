defmodule <%= @module_prefix %>.PetalComponents do
  defmacro __using__(_) do
    quote do
      alias <%= @module_prefix %>.PetalComponents

      <%=
        @components
        |> Enum.map(fn {module, _file} ->
          module_name =
            module
            |> Module.split()
            |> Enum.join(".")

          "import PetalComponents.#{module_name}\n"
        end)
      %>
    end
  end
end
