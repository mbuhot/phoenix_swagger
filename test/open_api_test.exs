defmodule PhoenixSwagger.OpenAPITest do
  use ExUnit.Case
  alias PhoenixSwagger.OpenAPI.{
    ContactObject,
    InfoObject,
    LicenseObject,
    OpenAPIObject,
    OperationObject,
    PathItemObject,
    PathsObject,
    ServerObject
  }

  defmodule UserController do
    use Phoenix.Controller

    def show_operation() do
      import OperationObject
      %OperationObject{
        tags: ["users"],
        summary: "Show user",
        description: "Show a user by ID",
        operationId: "UserController.show",
        parameters: [
          parameter(:id, :path, :integer, "User ID", example: 123)
        ],
        responses: %{
          200 => response("User", "application/json", "#/components/schemas/user")
        }
      }
    end
    def show(conn, _params) do
      conn
      |> Plug.Conn.send_resp(200, "HELLO")
    end

    def index_operation() do
      import OperationObject
      %OperationObject{
        tags: ["users"],
        summary: "List users",
        description: "List all useres",
        operationId: "UserController.index",
        parameters: [],
        responses: %{
          200 => response("User List Response", "application/json", "#/components/schemas/user_list")
        }
      }
    end
    def index(conn, _params) do
      conn
      |> Plug.Conn.send_resp(200, "HELLO")
    end

    def create_operation() do
      import OperationObject
      %OperationObject{
        tags: ["users"],
        summary: "Create user",
        description: "Create a user",
        operationId: "UserController.create",
        parameters: [],
        requestBody: request_body("The user attributes", "application/json", "#/components/schemas/new_user"),
        responses: %{
          201 => response("User", "application/json", "#/components/schemas/user")
        }
      }
    end
    def create(conn, _params) do
      conn
      |> Plug.Conn.send_resp(201, "DONE")
    end

    def open_api_operation(action), do: apply(__MODULE__, :"#{action}_operation", [])
  end

  defmodule TestRouter do
    use Phoenix.Router

    scope "/api" do
      resources "/users", UserController, only: [:create, :index, :show]
    end
  end

  describe "OpenAPIObject" do
    test "compete" do
      spec =
        %OpenAPIObject{
          servers: [
            %ServerObject{url: "http://example.com"},
            ServerObject.from_endpoint(TestEndpoint, otp_app: :phoenix_swagger)
          ],
          info: %InfoObject{
            title: "A",
            version: "3.0",
            contact: %ContactObject{
              name: "joe",
              email: "Joe@gmail.com",
              url: "https://help.joe.com"
            },
            license: %LicenseObject{
              name: "MIT",
              url: "http://mit.edu/license"
            }
          },
          paths: PathsObject.from_router(TestRouter)
        }

      assert spec
    end
  end

  describe "ServerObject" do
    test "from_endpoint" do
      Application.put_env(:phoenix_swagger, TestEndpoint, [
        url: [host: "example.com", port: 1234, path: "/api/v1/", scheme: :https],
      ])

      server = ServerObject.from_endpoint(TestEndpoint, otp_app: :phoenix_swagger)

      assert %{
        url: "https://example.com:1234/api/v1/"
      } = server
    end
  end

  describe "PathsObject" do
    test "from_router" do
      paths = PathsObject.from_router(TestRouter)
      assert %{
        "/api/users" => %PathItemObject{},
      } = paths
    end
  end

  describe "PathItemObject" do
    test "from_routes" do
      routes =
        for route <- TestRouter.__routes__(),
            route.path == "/api/users",
            do: route

      path_item = PathItemObject.from_routes(routes)
      assert path_item == %PathItemObject{
        get: UserController.index_operation(),
        post: UserController.create_operation()
      }
    end
  end

  describe "OperationObject" do
    test "from_route" do
      route = %{plug: UserController, opts: :show}
      assert OperationObject.from_route(route) == UserController.show_operation()
    end

    test "from_plug" do
      assert OperationObject.from_plug(UserController, :show) == UserController.show_operation()
    end
  end
end