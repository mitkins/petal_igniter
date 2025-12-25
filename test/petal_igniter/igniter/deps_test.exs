defmodule PetalIgniter.Igniter.Project.DepsTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias PetalIgniter.Igniter.Project.Deps

  describe "check_and_add_dep/3" do
    test "adds dependency when it doesn't exist" do
      test_project()
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:new_dep, "~> 1.0"}])
      |> assert_has_patch("mix.exs", """
        {:new_dep, "~> 1.0"}
      """)
    end

    test "upgrades dependency when desired version is higher" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 2.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2.0"}
      """)
    end

    test "keeps existing dependency when desired version is lower" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 2.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.0"}])
      |> refute_has_patch("mix.exs", """
        {:some_dep, "~> 1.0"}
      """)
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2.0"}
      """)
    end

    test "keeps existing dependency when versions are equal" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 1.0"}
      """)
    end

    test "handles >= version requirements" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, ">= 1.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, ">= 2.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, ">= 2.0"}
      """)
    end

    test "handles == version requirements" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "== 1.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "== 2.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "== 2.0"}
      """)
    end

    test "handles compound 'or' requirements" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.0 or ~> 2.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 3.0 or ~> 4.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 3.0 or ~> 4.0"}
      """)
    end

    test "handles compound 'and' requirements" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.0 and < 2.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 2.0 and < 3.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2.0 and < 3.0"}
      """)
    end

    test "handles dependency with options" do
      test_project()
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [
        {:new_dep, "~> 1.0", [only: :test]}
      ])
      |> assert_has_patch("mix.exs", """
        {:new_dep, "~> 1.0", [only: :test]}
      """)
    end

    test "upgrades dependency with options when version is higher" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.0", [only: :dev]})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [
        {:some_dep, "~> 2.0", [only: :dev]}
      ])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2.0", [only: :dev]}
      """)
    end

    test "compares versions with different patch levels correctly" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.2.3"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.2.4"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 1.2.4"}
      """)
    end

    test "compares versions with different minor levels correctly" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.2"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.3"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 1.3"}
      """)
    end

    test "compares versions with different major levels correctly" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 2.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2.0"}
      """)
    end

    test "normalizes single digit versions correctly" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 2"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2"}
      """)
    end

    test "normalizes two digit versions correctly" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.5"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.6"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 1.6"}
      """)
    end

    test "prevents downgrade from higher to lower major version" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 3.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.0"}])
      |> refute_has_patch("mix.exs", """
        {:some_dep, "~> 1.0"}
      """)
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 3.0"}
      """)
    end

    test "prevents downgrade from higher to lower minor version" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.5"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.3"}])
      |> refute_has_patch("mix.exs", """
        {:some_dep, "~> 1.3"}
      """)
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 1.5"}
      """)
    end

    test "prevents downgrade from higher to lower patch version" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "~> 1.2.5"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 1.2.3"}])
      |> refute_has_patch("mix.exs", """
        {:some_dep, "~> 1.2.3"}
      """)
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 1.2.5"}
      """)
    end

    test "handles mix of version requirement types" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, ">= 1.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 2.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2.0"}
      """)
    end

    test "handles upgrade from == to ~>" do
      test_project()
      |> Igniter.Project.Deps.add_dep({:some_dep, "== 1.0"})
      |> Igniter.apply_func_with_return(Deps, :check_and_add_dep, [{:some_dep, "~> 2.0"}])
      |> assert_has_patch("mix.exs", """
        {:some_dep, "~> 2.0"}
      """)
    end
  end
end
