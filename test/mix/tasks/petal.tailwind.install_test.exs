defmodule Mix.Tasks.Petal.Tailwind.InstallTest do
  use ExUnit.Case, async: true
  import Igniter.Test
  import PetalIgniter.Igniter.Test

  describe "basic functionality" do
    test "adds tailwind dependency" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.tailwind.install", [])
      |> assert_has_patch("mix.exs", """
        + |      {:tailwind, "~> 0.4", runtime: Mix.env() == :dev}
      """)
    end

    test "configures tailwind in config.exs" do
      test_project(app_name: :my_app)
      |> Igniter.create_new_file("config/config.exs", """
      import Config

      config :tailwind,
        version: "4.1.7",
        my_app: [
          args: ~w(
            --input=assets/css/app.css
            --output=priv/static/assets/css/app.css
          ),
          cd: Path.expand("..", __DIR__)
        ]
      """)
      |> apply_igniter!()
      |> Igniter.compose_task("petal.tailwind.install", [])
      |> assert_has_patch("config/config.exs", """
        + |  version: "4.1.13"
      """)
    end

    test "configures tailwind for a Phoenix 1.7 project" do
      test_project(app_name: :my_app)
      |> Igniter.create_new_file("config/config.exs", """
      import Config

      config :tailwind,
        version: "3.4.3",
        my_app: [
          args: ~w(
            --config=tailwind.config.js
            --input=css/app.css
            --output=../priv/static/assets/css/app.css
          ),
          cd: Path.expand("../assets", __DIR__)
        ]
      """)
      |> apply_igniter!()
      |> Igniter.compose_task("petal.tailwind.install", [])
      |> assert_has_patch("config/config.exs", """
        + |  version: "4.1.13"
      """)
      |> assert_has_patch("config/config.exs", """
        + |  --input=assets/css/app.css
      """)
      |> assert_has_patch("config/config.exs", """
        + |  --output=priv/static/assets/css/app.css
      """)
      |> assert_has_patch("config/config.exs", """
        + |  cd: Path.expand(\"..\", __DIR__)
      """)
    end
  end

  describe "--lib flag" do
    test "does not install dependency with --lib flag" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.tailwind.install", ["--lib"])
      |> refute_has_patch("mix.exs", """
        + |      {:tailwind, "~> 0.4",
      """)
    end

    test "does not configure tailwind with --lib flag" do
      test_project(app_name: :my_app)
      |> Igniter.compose_task("petal.tailwind.install", ["--lib"])
      |> refute_has_patch("config/config.exs", """
        + |config :tailwind, version: "4.1.13"
      """)
    end
  end
end
