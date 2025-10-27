defmodule PetalIgniter.Components do
  @components [
    %{
      module: Loading,
      file: "loading.ex",
      test_file: "loading_test.exs",
      css_file: "loading.css"
    },
    %{
      module: Link,
      file: "link.ex",
      test_file: "link_test.exs",
      css_file: nil
    },
    %{
      module: Icon,
      file: "icon.ex",
      test_file: "icon_test.exs",
      css_file: nil
    },
    %{
      module: Button,
      file: "button.ex",
      test_file: "button_test.exs",
      css_file: "button.css"
    }
  ]

  def list(), do: @components

  def components() do
    @components
    |> Enum.filter(fn component -> component.file != nil end)
    |> Enum.map(fn component -> {component.module, component.file} end)
  end

  def tests() do
    @components
    |> Enum.filter(fn component -> component.test_file != nil end)
    |> Enum.map(fn component -> {component.module, component.test_file} end)
  end

  def css_files() do
    @components
    |> Enum.filter(fn component -> component.css_file != nil end)
    |> Enum.map(fn component -> component.css_file end)
  end
end
