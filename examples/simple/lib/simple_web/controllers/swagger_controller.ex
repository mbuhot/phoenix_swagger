defmodule SimpleWeb.SwaggerController do
  def init(:show), do: []
  def call(conn, []) do
    Phoenix.Controller.json(conn, SimpleWeb.APISpec.spec() |> PhoenixSwagger.OpenAPI.to_json())
  end
end