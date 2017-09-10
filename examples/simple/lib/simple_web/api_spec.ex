defmodule SimpleWeb.ApiSpec do
  alias PhoenixSwagger.OpenAPI.{
    ComponentsObject,
    ContactObject,
    InfoObject,
    OpenAPIObject,
    PathsObject,
    ReferenceObject,
    SchemaObject,
    ServerObject,
  }

  def spec do
    %OpenAPIObject{
      info: %InfoObject{
        version: "1.0",
        title: "Simple App",
        contact: %ContactObject{
          name: "joe",
          email: "Joe@gmail.com",
          url: "https://help.joe.com"
        }
      },
      servers: [ServerObject.from_endpoint(SimpleWeb.Endpoint, otp_app: :simple)],
      paths: PathsObject.from_router(SimpleWeb.Router),
      components: %ComponentsObject{
        schemas: %{
          "user" => %SchemaObject{
            title: "User",
            description: "A user of the app",
            type: :object,
            properties: %{
              id: %SchemaObject{type: :integer, description: "User ID"},
              name:  %SchemaObject{type: :string, description: "User name"},
              email: %SchemaObject{type: :string, description: "Email address", format: :email},
              inserted_at: %SchemaObject{type: :string, description: "Creation timestamp", format: :datetime},
              updated_at: %SchemaObject{type: :string, description: "Update timestamp", format: :datetime}
            },
            example: %{
              id: 123,
              name: "Joe",
              email: "joe@gmail.com"
            }
          },
          "user_request" => %SchemaObject{
            title: "UserRequest",
            description: "POST body for creating a user",
            type: :object,
            properties: %{
              user: %ReferenceObject{"$ref": "#/components/schemas/user"}
            }
          },
          "user_response" => %SchemaObject{
            title: "UserResponse",
            description: "Response schema for single user",
            type: :object,
            properties: %{
              data: %ReferenceObject{"$ref": "#/components/schemas/user"}
            }
          },
          "users_response" => %SchemaObject{
            title: "UsersReponse",
            description: "Response schema for multiple users",
            type: :object,
            properties: %{
              data: %SchemaObject{description: "The users details", type: :array, items: %ReferenceObject{"$ref": "#/components/schemas/user"}}
            }
          }
        }
      }
    }
  end
end