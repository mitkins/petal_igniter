defmodule PetalIgniter.Igniter.Project.Deps do
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

  defp normalize_min(v) do
    parts = String.split(v, ".") |> Enum.map(&String.to_integer/1)

    case parts do
      [maj] -> "#{maj}.0.0"
      [maj, min] -> "#{maj}.#{min}.0"
      [maj, min, pat] -> "#{maj}.#{min}.#{pat}"
    end
  end
end
