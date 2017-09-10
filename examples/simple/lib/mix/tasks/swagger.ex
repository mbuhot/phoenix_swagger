defmodule Mix.Tasks.Simple.Swagger do
  use Mix.Task

  def run(_) do
    SimpleWeb.ApiSpec.spec()
    |> PhoenixSwagger.OpenAPI.to_json()
    |> Poison.encode!(pretty: true)
    |> IO.puts()
  end
end