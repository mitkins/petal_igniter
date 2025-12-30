defmodule Mix.Tasks.PetalComponents.CssTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  describe "basic functionality" do
    test "generates CSS files for all components by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", [])
      |> assert_creates("assets/css/petal_components/button.css")
      |> assert_creates("assets/css/petal_components/accordion.css")
      |> assert_creates("assets/css/petal_components/dropdown.css")
    end

    test "generates default CSS file" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", [])
      |> assert_creates("assets/css/petal_components.css")
    end

    test "generates colors CSS file" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", [])
      |> assert_creates("assets/css/colors.css")
    end

    test "adds CSS imports to app.css" do
      test_project(app_name: :my_app)
      |> Igniter.create_new_file("assets/css/app.css", "/* test css */")
      |> apply_igniter!()
      |> Igniter.compose_task("petal_components.css", [])
      |> assert_has_patch("assets/css/app.css", """
        + |  @import "./petal_components.css";
      """)
      |> assert_has_patch("assets/css/app.css", """
        + |  @import "./colors.css";
      """)
    end

    test "adds Tailwind plugins to app.css" do
      test_project(app_name: :my_app)
      |> Igniter.create_new_file("assets/css/app.css", "/* test css */")
      |> apply_igniter!()
      |> Igniter.compose_task("petal_components.css", [])
      |> assert_has_patch("assets/css/app.css", """
        + |  @plugin "@tailwindcss/typography";
      """)
      |> assert_has_patch("assets/css/app.css", """
        + |  @plugin "@tailwindcss/forms";
      """)
    end
  end

  describe "component selection with --component flag" do
    test "generates CSS only for specified components" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", ["--component", "button"])
      |> assert_creates("assets/css/petal_components/button.css")
      |> refute_creates("assets/css/petal_components/accordion.css")
    end

    test "generates CSS for multiple specified components" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", [
        "--component",
        "button",
        "--component",
        "dropdown"
      ])
      |> assert_creates("assets/css/petal_components/button.css")
      |> assert_creates("assets/css/petal_components/dropdown.css")
      |> refute_creates("assets/css/petal_components/accordion.css")
    end

    test "uses short alias -c for component selection" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", ["-c", "button", "-c", "icon"])
      |> assert_creates("assets/css/petal_components/button.css")
    end

    test "includes component dependencies by default" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", ["--component", "button"])
      |> assert_creates("assets/css/petal_components/button.css")
      |> assert_creates("assets/css/petal_components/loading.css")
    end

    test "excludes component dependencies when --no-deps flag is provided" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", ["--component", "button", "--no-deps"])
      |> assert_creates("assets/css/petal_components/button.css")
      |> refute_creates("assets/css/petal_components/loading.css")
    end
  end

  describe "component validation and error handling" do
    test "rejects invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", ["--component", "invalid_component"])
      |> assert_has_issue("'invalid_component' is not a valid component name")
    end

    test "rejects multiple invalid component names" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", [
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
      |> Igniter.compose_task("petal_components.css", [
        "--component",
        "button",
        "--component",
        "invalid_component"
      ])
      |> assert_has_issue("'invalid_component' is not a valid component name")
    end
  end

  describe "--lib flag" do
    test "generates CSS in lib location when --lib flag is provided" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", ["--lib", "--component", "button"])
      |> assert_creates("assets/css/petal_components/button.css")
      |> assert_creates("assets/css/default.css")
    end

    test "does not generate colors.css in lib mode" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", ["--lib"])
      |> refute_creates("assets/css/colors.css")
    end
  end

  describe "missing app.css handling" do
    test "adds warning when app.css does not exist" do
      # test_project does not create assets/css/app.css
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal_components.css", [])
      |> assert_has_warning("Could not find assets/css/app.css. Skipping CSS imports.")
    end
  end
end
