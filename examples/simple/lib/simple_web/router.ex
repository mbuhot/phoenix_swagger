defmodule SimpleWeb.Router do
  use SimpleWeb, :router
  alias PhoenixSwagger.Plug.Validate

  pipeline :api do
    plug :accepts, ["json"]
    # plug Validate, validation_failed_status: 422
  end

  scope "/api", SimpleWeb do
    pipe_through :api
    resources "/users", UserController, except: [:new, :edit]
  end

  scope "/api/swagger" do
    get "/swagger.json", SimpleWeb.SwaggerController, :show
    forward "/", PhoenixSwagger.Plug.SwaggerUI, swagger_url: "swagger.json"
  end
end
