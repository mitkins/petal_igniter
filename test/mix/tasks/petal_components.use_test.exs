defmodule Mix.Tasks.PetalComponents.UseTest do
  use ExUnit.Case, async: true
  import Igniter.Test
  import PetalIgniter.Igniter.Test

  @moduletag :igniter

  describe "basic functionality" do
    test "creates PetalComponents module file in correct location" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", [])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
    end

    test "skips all work when --lib flag is provided" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["--lib"])
      |> assert_unchanged()
    end
  end

  describe "component selection with --component flag" do
    test "includes only specified components with --component flag" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["--component", "button"])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Button
      """)
      |> refute_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Accordian
      """)
    end

    test "includes multiple components with multiple --component flags" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", [
        "--component",
        "button",
        "--component",
        "dropdown"
      ])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Button
      """)
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Dropdown
      """)
    end

    test "uses short alias -c for component selection" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["-c", "button", "-c", "icon"])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Button
      """)
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Icon
      """)
    end

    test "includes component dependencies by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["--component", "button"])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Button
        |  import PetalComponents.Icon
        |  import PetalComponents.Link
        |  import PetalComponents.Loading
      """)
    end

    test "excludes component dependencies when --no-deps flag is provided" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["--component", "button", "--no-deps"])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Button
      """)
      |> refute_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.Icon
      """)
    end
  end

  describe "component validation and error handling" do
    test "rejects invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["--component", "invalid_component"])
      |> assert_has_issue("'invalid_component' is not a valid component name")
    end

    test "rejects multiple invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", [
        "--component",
        "invalid1",
        "--component",
        "invalid2"
      ])
      |> assert_has_issue("'invalid1' is not a valid component name")
      |> assert_has_issue("'invalid2' is not a valid component name")
    end

    test "handles mix of valid and invalid components" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", [
        "--component",
        "button",
        "--component",
        "invalid_component"
      ])
      |> assert_has_issue("'invalid_component' is not a valid component name")
    end
  end

  describe "component name variations" do
    test "accepts snake_case component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["--component", "user_dropdown_menu"])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.UserDropdownMenu
      """)
    end

    test "converts CamelCase to snake_case component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.use", ["--component", "UserDropdownMenu"])
      |> assert_creates("lib/my_app_web/components/petal_components.ex")
      |> assert_has_patch("lib/my_app_web/components/petal_components.ex", """
        |  import PetalComponents.UserDropdownMenu
      """)
    end
  end
end
