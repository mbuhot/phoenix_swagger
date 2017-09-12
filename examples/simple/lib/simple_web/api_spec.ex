defmodule SimpleWeb.APISpec do
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
          }
        }
      }
    }
    |> PhoenixSwagger.OpenAPI.resolve_schema_modules()
  end
end