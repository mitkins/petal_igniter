defmodule PetalIgniter.Components do
  @components [
    %{module: Loading, file: "loading.ex", test_file: "loading_test.exs"},
    %{module: Link, file: "link.ex", test_file: "link_test.exs"},
    %{module: Icon, file: "icon.ex", test_file: "icon_test.exs"},
    %{module: Button, file: "button.ex", test_file: "button_test.exs"}
  ]

  def list(), do: @components
end
