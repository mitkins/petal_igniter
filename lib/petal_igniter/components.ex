defmodule PetalIgniter.Components do
  @components [
    %{
      module: Accordion,
      file: "accordion.ex",
      test_file: "accordion_test.exs",
      css_file: "accordion.css"
    },
    %{
      module: Alert,
      file: "alert.ex",
      test_file: "alert_test.exs",
      css_file: "alert.css"
    },
    %{
      module: Avatar,
      file: "avatar.ex",
      test_file: "avatar_test.exs",
      css_file: "avatar.css"
    },
    %{
      module: Badge,
      file: "badge.ex",
      test_file: "badge_test.exs",
      css_file: "badge.css"
    },
    %{
      module: Button,
      file: "button.ex",
      test_file: "button_test.exs",
      css_file: "button.css"
    },
    %{
      module: Icon,
      file: "icon.ex",
      test_file: "icon_test.exs",
      css_file: nil
    },
    %{
      module: Link,
      file: "link.ex",
      test_file: "link_test.exs",
      css_file: nil
    },
    %{
      module: Loading,
      file: "loading.ex",
      test_file: "loading_test.exs",
      css_file: "loading.css"
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
