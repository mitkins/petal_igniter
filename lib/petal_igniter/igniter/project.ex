defmodule PetalIgniter.Igniter.Project do
  @spec priv_dir(Igniter.t(), [String.t()]) :: String.t()
  def priv_dir(igniter, subpath \\ []) do
    # App path always overrides library path. Unless you're using the --lib option - where the lib _is_
    # the app
    app_path =
      Igniter.Project.Application.priv_dir(igniter, subpath)

    # But only if the path/file exists
    if File.exists?(app_path) do
      app_path
    else
      lib_name = Application.get_application(__MODULE__)
      Path.join(["_build/#{Mix.env()}/lib/", to_string(lib_name), "priv"] ++ subpath)
    end
  end

  @spec component_template(Igniter.t(), String.t()) :: String.t()
  def component_template(igniter, file), do: priv_dir(igniter, ["templates", "component", file])

  @spec css_template(Igniter.t(), String.t()) :: String.t()
  def css_template(igniter, file), do: priv_dir(igniter, ["templates", "css", file])

  @spec test_template(Igniter.t(), String.t()) :: String.t()
  def test_template(igniter, file), do: priv_dir(igniter, ["templates", "test", file])
end
