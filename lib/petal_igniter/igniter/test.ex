defmodule PetalIgniter.Igniter.Test do
  @moduledoc "Tools for testing with igniter."

  import ExUnit.Assertions

  def refute_has_patch(igniter, path, patch) do
    # Copied from Igniter.Test.assert_has_patch/3
    diff =
      igniter.rewrite.sources
      |> Map.take([path])
      |> Igniter.diff(color?: false)

    compare_diff =
      Igniter.Test.sanitize_diff(diff)

    compare_patch =
      Igniter.Test.sanitize_diff(patch, diff)

    compare_diff =
      if Igniter.Test.has_line_numbers?(compare_patch) do
        compare_diff
      else
        Igniter.Test.remove_line_numbers(compare_diff)
      end

    refute String.contains?(compare_diff, compare_patch),
           """
           Expected `#{path}` to not contain the following patch:

           #{patch}

           Actual diff:

           #{diff}
           """

    igniter
  end
end
