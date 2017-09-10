defmodule Mix.Tasks.Simple.Swagger do
  use Mix.Task

  def run(_) do
    spec =
      SimpleWeb.APISpec.spec()
      |> PhoenixSwagger.OpenAPI.to_json()
      |> Poison.encode!(pretty: true)

    File.write!("priv/static/swagger.json", spec)
  end
end