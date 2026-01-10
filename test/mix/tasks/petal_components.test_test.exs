defmodule Mix.Tasks.PetalComponents.TestTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  @moduletag :igniter

  describe "basic functionality" do
    test "generates component_case support module" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", [])
      |> assert_creates("test/support/component_case.ex")
    end

    test "generates test files for all components by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", [])
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/accordion_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/dropdown_test.exs")
    end

    test "skips pagination_internal component tests" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", [])
      |> refute_creates(
        "test/my_app_web/components/petal_components/pagination_internal_test.exs"
      )
    end
  end

  describe "component selection with --component flag" do
    test "generates tests only for specified components" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["--component", "button"])
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
      |> refute_creates("test/my_app_web/components/petal_components/accordion_test.exs")
    end

    test "generates tests for multiple specified components" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", [
        "--component",
        "button",
        "--component",
        "dropdown"
      ])
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/dropdown_test.exs")
      |> refute_creates("test/my_app_web/components/petal_components/accordion_test.exs")
    end

    test "uses short alias -c for component selection" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["-c", "button", "-c", "icon"])
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/icon_test.exs")
    end

    test "includes component dependencies by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["--component", "button"])
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/icon_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/link_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/loading_test.exs")
    end

    test "excludes component dependencies when --no-deps flag is provided" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["--component", "button", "--no-deps"])
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
      |> refute_creates("test/my_app_web/components/petal_components/icon_test.exs")
      |> refute_creates("test/my_app_web/components/petal_components/link_test.exs")
    end
  end

  describe "component validation and error handling" do
    test "rejects invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["--component", "invalid_component"])
      |> assert_has_issue("'invalid_component' is not a valid component name")
    end

    test "rejects multiple invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", [
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
      |> Igniter.compose_task("petal_components.test", [
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
      |> Igniter.compose_task("petal_components.test", ["--component", "user_dropdown_menu"])
      |> assert_creates("test/my_app_web/components/petal_components/user_dropdown_menu_test.exs")
    end

    test "converts CamelCase to snake_case component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["--component", "UserDropdownMenu"])
      |> assert_creates("test/my_app_web/components/petal_components/user_dropdown_menu_test.exs")
    end
  end

  describe "--lib flag" do
    test "generates tests in lib location when --lib flag is provided" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["--lib", "--component", "button"])
      |> assert_creates("test/my_app/button_test.exs")
      |> refute_creates("test/my_app_web/components/petal_components/button_test.exs")
    end
  end

  describe "--js-lib option" do
    test "accepts --js-lib option with default value" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", ["--component", "button"])
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
    end

    test "rejects custom --js-lib option" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.test", [
        "--component",
        "button",
        "--js-lib",
        "htmx"
      ])
      |> assert_has_warning(
        "Unknown option 'htmx' - valid arguments for js_lib are 'alpine_js' and 'live_view_js'"
      )
    end
  end
end
