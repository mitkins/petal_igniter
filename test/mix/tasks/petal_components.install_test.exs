defmodule Mix.Tasks.PetalComponents.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  test "it warns when run" do
    # generate a test project
    test_project(app_name: :petal_igniter)
    # run our task
    |> Igniter.compose_task("petal_components.install", ["--lib"])
    # see tools in `Igniter.Test` for available assertions & helpers
    |> assert_creates("assets/css/default.css")
    |> assert_creates("lib/petal_igniter/button.ex")
    |> assert_creates("lib/petal_igniter/icon.ex")
    |> assert_creates("lib/petal_igniter/link.ex")
    |> assert_creates("test/petal_igniter/button_test.exs")
    |> assert_creates("test/petal_igniter/icon_test.exs")
    |> assert_creates("test/petal_igniter/link_test.exs")

    # |> assert_has_warning("mix petal_components.install is not yet implemented")
  end
end
