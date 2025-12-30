defmodule Mix.Tasks.PetalComponents.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  describe "basic functionality" do
    test "installs all components with --lib flag" do
      test_project(app_name: :my_lib)
      |> Igniter.compose_task("petal_components.install", ["--lib"])
      |> assert_creates("assets/css/default.css")
      |> assert_creates("lib/my_lib/accordion.ex")
      |> assert_creates("lib/my_lib/button.ex")
      |> assert_creates("lib/my_lib/icon.ex")
      |> assert_creates("lib/my_lib/link.ex")
      |> assert_creates("test/my_lib/accordion_test.exs")
      |> assert_creates("test/my_lib/button_test.exs")
      |> assert_creates("test/my_lib/icon_test.exs")
      |> assert_creates("test/my_lib/link_test.exs")
    end

    test "installs all components in web location by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", [])
      |> assert_creates("assets/css/petal_components.css")
      |> assert_creates("lib/my_app_web/components/petal_components/accordion.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/button.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/icon.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/link.ex")
      |> assert_creates("test/my_app_web/components/petal_components/accordion_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/button_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/icon_test.exs")
      |> assert_creates("test/my_app_web/components/petal_components/link_test.exs")
    end

    test "creates helpers file in lib location with --lib flag" do
      test_project(app_name: :my_lib)
      |> Igniter.compose_task("petal_components.install", ["--lib"])
      |> assert_creates("lib/my_lib/helpers.ex")
    end

    test "creates helpers file in web location by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", [])
      |> assert_creates("lib/my_app_web/components/petal_components/helpers.ex")
    end

    test "adds required dependencies" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", [])
      |> assert_has_patch("mix.exs", """
        |      {:phoenix_live_view, "~> 1.1"}
      """)
      |> assert_has_patch("mix.exs", """
        |      {:phoenix_ecto, "~> 4.4"}
      """)
      |> assert_has_patch("mix.exs", """
        |      {:phoenix_html_helpers, "~> 1.0"}
      """)
      |> assert_has_patch("mix.exs", """
        |      {:lazy_html, ">= 0.0.0", only: :test}
      """)
    end
  end

  describe "component selection with --component flag" do
    test "installs only specified components" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", ["--component", "button"])
      |> assert_creates("lib/my_app_web/components/petal_components/button.ex")
      |> refute_creates("lib/my_app_web/components/petal_components/accordion.ex")
      |> refute_creates("lib/my_app_web/components/petal_components/dropdown.ex")
    end

    test "installs multiple specified components" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", [
        "--component",
        "button",
        "--component",
        "dropdown"
      ])
      |> assert_creates("lib/my_app_web/components/petal_components/button.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/dropdown.ex")
      |> refute_creates("lib/my_app_web/components/petal_components/accordion.ex")
    end

    test "uses short alias -c for component selection" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", ["-c", "button", "-c", "icon"])
      |> assert_creates("lib/my_app_web/components/petal_components/button.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/icon.ex")
      |> refute_creates("lib/my_app_web/components/petal_components/accordion.ex")
    end

    test "includes component dependencies by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", ["--component", "button"])
      |> assert_creates("lib/my_app_web/components/petal_components/button.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/icon.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/link.ex")
      |> assert_creates("lib/my_app_web/components/petal_components/loading.ex")
    end

    test "excludes component dependencies when --no-deps flag is provided" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", [
        "--component",
        "button",
        "--no-deps"
      ])
      |> assert_creates("lib/my_app_web/components/petal_components/button.ex")
      |> refute_creates("lib/my_app_web/components/petal_components/icon.ex")
      |> refute_creates("lib/my_app_web/components/petal_components/link.ex")
    end
  end

  describe "component validation and error handling" do
    test "rejects invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", ["--component", "invalid_component"])
      |> assert_has_issue("'invalid_component' is not a valid component name")
    end

    test "rejects multiple invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", [
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
      |> Igniter.compose_task("petal_components.install", [
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
      |> Igniter.compose_task("petal_components.install", [
        "--component",
        "user_dropdown_menu"
      ])
      |> assert_creates("lib/my_app_web/components/petal_components/user_dropdown_menu.ex")
    end

    test "converts CamelCase to snake_case component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", ["--component", "UserDropdownMenu"])
      |> assert_creates("lib/my_app_web/components/petal_components/user_dropdown_menu.ex")
    end
  end

  describe "--js-lib option" do
    test "accepts --js-lib option with default value" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", ["--component", "button"])
      |> assert_creates("lib/my_app_web/components/petal_components/button.ex")
    end

    test "accepts custom --js-lib option" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.install", [
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
