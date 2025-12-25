defmodule PetalIgniter.Igniter.Project.Deps do
  @moduledoc """
  Utilities for inspecting and modifying project dependencies in an Igniter project.

  Main difference between this and Igniter.Project.Deps is that it will only add
  the dependency if it doesn't exist or it is a higher version.
  """

  @doc """
  Ensures a dependency is present in the project without downgrading its version.
  Given an `igniter` project context and a dependency tuple, this function:

  * Looks up the existing dependency by name in the project
  * Compares the minimum version implied by the existing requirement with the
    minimum version implied by the desired requirement
  * Adds or updates the dependency via `Igniter.Project.Deps.add_dep/3` only if
    the desired requirement requires a strictly newer minimum version
  * Leaves the project unchanged if the existing requirement is equal to or
    newer than the desired one
  * Records an issue on the `igniter` via `Igniter.add_issue/2` if the existing
    dependency cannot be retrieved or parsed

  The `dep` argument is expected to be either `{name, requirement}` or
  `{name, requirement, dep_opts}`, where `name` is an atom and `requirement`
  is a version requirement string.

  Returns the (possibly updated) `igniter` project context.
  """
  def check_and_add_dep(igniter, dep, opts \\ []) do
    {name, desired_req} = name_and_req(dep)

    with {:ok, {_found_name, found_req}} when is_binary(found_req) <- get_dep(igniter, name) do
      # Check minimum version here and balk if there's an issue
      found_min = min_from_requirement!(found_req)
      desired_min = min_from_requirement!(desired_req)

      case Version.compare(desired_min, found_min) do
        :lt ->
          igniter

        :eq ->
          igniter

        :gt ->
          Igniter.Project.Deps.add_dep(igniter, dep, opts)
      end
    else
      {:ok, unsupported_req} ->
        Igniter.add_issue(
          igniter,
          "Failed to check_and_add_dep dependency '#{name}' - #{inspect(unsupported_req)}"
        )

      {:error, :not_found} ->
        Igniter.Project.Deps.add_dep(igniter, dep, opts)

      {:error, {:parse_error, reason}} ->
        Igniter.add_issue(igniter, "Failed to parse dep #{name}: #{inspect(reason)}")

      {:error, {:retrieval_error, reason}} ->
        Igniter.add_issue(igniter, "Failed to get dep #{name}: #{inspect(reason)}")
    end
  end

  defp get_dep(igniter, name) do
    case Igniter.Project.Deps.get_dep(igniter, name) do
      {:ok, dep_string} when is_binary(dep_string) ->
        case Code.string_to_quoted(dep_string) do
          {:ok, quoted_dep} -> {:ok, quoted_dep}
          {:error, reason} -> {:error, {:parse_error, reason}}
        end

      {:ok, nil} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, {:retrieval_error, reason}}
    end
  end

  defp name_and_req({name, req}), do: {name, req}
  defp name_and_req({name, req, _req_opts}), do: {name, req}

  defp min_from_requirement!("~> " <> rest), do: normalize_min(rest)
  defp min_from_requirement!(">= " <> rest), do: normalize_min(rest)
  defp min_from_requirement!("== " <> rest), do: normalize_min(rest)

  defp min_from_requirement!(req) when is_binary(req) do
    cond do
      String.contains?(req, " or ") ->
        # Compound requirement, e.g. "~> 1.0 or ~> 2.0" – take the first disjunct
        String.split(req, " or ", parts: 2)
        |> hd()
        |> String.trim()
        |> min_from_requirement!()

      String.contains?(req, " and ") ->
        # Compound requirement, e.g. "~> 1.0 and <= 2.0" – take the first disjunct
        String.split(req, " and ", parts: 2)
        |> hd()
        |> String.trim()
        |> min_from_requirement!()

      true ->
        # Unsupported format
        raise ArgumentError, "Unsupported version requirement format: #{inspect(req)}"
    end
  end

  defp normalize_min(v) do
    parts = String.split(v, ".")

    case parts do
      [maj] -> "#{maj}.0.0"
      [maj, min] -> "#{maj}.#{min}.0"
      [maj, min, pat] -> "#{maj}.#{min}.#{pat}"
    end
  end
end
