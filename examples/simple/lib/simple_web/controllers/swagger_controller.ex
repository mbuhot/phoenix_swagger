defmodule SimpleWeb.SwaggerController do
  alias Phoenix.Controller
  alias PhoenixSwagger.OpenAPI
  alias SimpleWeb.APISpec

  def init(opts), do: opts
  def call(conn, :show) do
    Controller.json(conn, APISpec.spec() |> OpenAPI.to_json())
  end
end