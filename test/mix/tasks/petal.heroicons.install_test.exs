defmodule Mix.Tasks.Petal.Heroicons.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test
  import PetalIgniter.Igniter.Test

  @moduletag :igniter

  describe "basic functionality" do
    test "adds heroicons dependency" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.heroicons.install", [])
      |> assert_has_patch("mix.exs", """
        + |  {:heroicons,
      """)
    end

    test "adds heroicons with correct GitHub configuration" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.heroicons.install", [])
      |> assert_has_patch("mix.exs", """
        + |   github: "tailwindlabs/heroicons",
      """)
      |> assert_has_patch("mix.exs", """
        + |   tag: "v2.2.0",
      """)
      |> assert_has_patch("mix.exs", """
        + |   sparse: "optimized",
      """)
    end

    test "creates tailwind_heroicons.js file" do
      test_project(app_name: :my_app)
      |> Igniter.create_new_file("assets/css/app.css", "/* test css */")
      |> apply_igniter!()
      |> Igniter.compose_task("petal.heroicons.install", [])
      |> assert_creates("assets/css/tailwind_heroicons.js")
    end

    test "adds tailwind_heroicons.js plugin to app.css" do
      test_project(app_name: :my_app)
      |> Igniter.create_new_file("assets/css/app.css", "/* test css */")
      |> apply_igniter!()
      |> Igniter.compose_task("petal.heroicons.install", [])
      |> assert_has_patch("assets/css/app.css", """
        + |@plugin "./tailwind_heroicons.js";
      """)
    end
  end

  describe "--lib flag" do
    test "installs only dependency with --lib flag" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.heroicons.install", ["--lib"])
      |> assert_has_patch("mix.exs", """
        + |  {:heroicons,
      """)
    end

    test "does not create tailwind_heroicons.js with --lib flag" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.heroicons.install", ["--lib"])
      |> refute_creates("assets/css/tailwind_heroicons.js")
    end

    test "does not modify app.css with --lib flag" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.heroicons.install", ["--lib"])
      |> refute_has_patch("assets/css/app.css", """
        + |@plugin "./tailwind_heroicons.js";
      """)
    end
  end

  describe "missing app.css handling" do
    test "adds warning when app.css does not exist" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.heroicons.install", [])
      |> assert_has_warning("Could not find assets/css/app.css. Skipping CSS imports.")
    end
  end
end
