defmodule SimpleWeb.UserController do
  use SimpleWeb, :controller
  use PhoenixSwagger

  alias Simple.Accounts
  alias Simple.Accounts.User
  alias SimpleWeb.Schemas.{UserRequest, UserResponse, UsersResponse}

  action_fallback SimpleWeb.FallbackController

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def index_operation do
    alias PhoenixSwagger.OpenAPI.OperationObject
    import OperationObject, only: [response: 4]

    %OperationObject{
      summary: "List Users",
      description: "List all users in the database",
      responses: %{
        200 => response("OK", "application/json", UsersResponse, example: %{
          data: [
            %{
              id: 1, name: "Joe", email: "Joe6@mail.com",
              inserted_at: "2017-02-08T12:34:55Z", updated_at: "2017-02-12T13:45:23Z"
            },
            %{
              id: 2, name: "Jack", email: "Jack7@mail.com",
              inserted_at: "2017-02-04T11:24:45Z", updated_at: "2017-02-15T23:15:43Z"
            }
          ]
        })
      }
    }
  end
  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create_operation do
    alias PhoenixSwagger.OpenAPI.OperationObject
    import OperationObject, only: [request_body: 4, response: 4]

    %OperationObject{
      summary: "Create user",
      description: "Creates a new user",
      requestBody: request_body("The user details", "application/json", UserRequest, example: %{
          user: %{name: "Joe", email: "Joe1@mail.com"}
        }),
      responses: %{
        201 => response("User created OK", "application/json", UserResponse, example: %{
          data: %{
            id: 1, name: "Joe", email: "Joe2@mail.com", inserted_at: "2017-02-08T12:34:55Z", updated_at: "2017-02-12T13:45:23Z"
          }
        })
      }
    }
  end
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end

  def show_operation do
    alias PhoenixSwagger.OpenAPI.OperationObject
    import OperationObject, only: [response: 4, parameter: 5]

    %OperationObject{
      summary: "Show User",
      description: "Show a user by ID",
      parameters: [
        parameter(:id, :path, :integer, "User ID", required: true, example: 123)
      ],
      responses: %{
        200 => response("OK", "application/json", UserResponse, example: %{
          data: %{
            id: 123, name: "Joe", email: "Joe3@mail.com",
            inserted_at: "2017-02-08T12:34:55Z", updated_at: "2017-02-12T13:45:23Z"
          }
        })
      }
    }
  end
  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def update_operation do
    alias PhoenixSwagger.OpenAPI.OperationObject
    import OperationObject, only: [parameter: 5, request_body: 4, response: 4, ]

    %OperationObject{
      summary: "Update user",
      description: "Update all attributes of a user",
      parameters: [
        parameter(:id, :path, :integer, "User ID", required: true, example: 3),
      ],
      requestBody: request_body("The user details", "application/json", UserRequest, example: %{
        user: %{name: "Joe", email: "joe4@mail.com"}
      }),
      responses: %{
        200 => response("Updated Successfully", "application/json", UserResponse, example: %{
          data: %{
            id: 3, name: "Joe", email: "Joe5@mail.com",
            inserted_at: "2017-02-08T12:34:55Z", updated_at: "2017-02-12T13:45:23Z"
          }
        })
      }
    }
  end
  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete_operation do
    alias PhoenixSwagger.OpenAPI.{OperationObject, ResponseObject}
    import OperationObject, only: [parameter: 5]

    %OperationObject{
      summary: "Delete User",
      description: "Delete a user by ID",
      parameters: [
        parameter(:id, :path, :integer, "User ID", required: true, example: 3)
      ],
      responses: %{
        204 => %ResponseObject{description: "No Content - Deleted Successfully"}
      }
    }
  end
  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
