defmodule SimpleWeb.Schemas do
  alias PhoenixSwagger.OpenAPI.SchemaObject

  defmodule User do
    def schema do
      %SchemaObject{
        title: "User",
        description: "A user of the app",
        type: :object,
        properties: %{
          id: %SchemaObject{type: :integer, description: "User ID"},
          name:  %SchemaObject{type: :string, description: "User name"},
          email: %SchemaObject{type: :string, description: "Email address", format: :email},
          inserted_at: %SchemaObject{type: :string, description: "Creation timestamp", format: :datetime},
          updated_at: %SchemaObject{type: :string, description: "Update timestamp", format: :datetime}
        }
      }
    end
  end
  defmodule UserRequest do
    def schema do
      %SchemaObject{
        title: "UserRequest",
        description: "POST body for creating a user",
        type: :object,
        properties: %{
          user: User
        }
      }
    end
  end
  defmodule UserResponse do
    def schema do
      %SchemaObject{
        title: "UserResponse",
        description: "Response schema for single user",
        type: :object,
        properties: %{
          data: User
        }
      }
    end
  end
  defmodule UsersResponse do
    def schema do
      %SchemaObject{
        title: "UsersReponse",
        description: "Response schema for multiple users",
        type: :object,
        properties: %{
          data: %SchemaObject{description: "The users details", type: :array, items: User}
        }
      }
    end
  end
end