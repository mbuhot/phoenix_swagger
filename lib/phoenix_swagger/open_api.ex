defmodule PhoenixSwagger.OpenAPI do
  defmodule ServerObject do
    alias PhoenixSwagger.OpenAPI.ServerVariableObject
    defstruct [
      :url,
      :description,
      variables: %{}
    ]
    @type t :: %ServerObject{
      url: String.t,
      description: String.t,
      variables: %{String.t => ServerVariableObject.t}
    }

    @doc """
    Builds a ServerObject from a phoenix Endpoint module
    """
    @spec from_endpoint(module, keyword) :: t
    def from_endpoint(endpoint, otp_app: app) do
      url_config = Application.get_env(app, endpoint, []) |> Keyword.get(:url, [])
      scheme = Keyword.get(url_config, :scheme, "http")
      host = Keyword.get(url_config, :host, "localhost")
      port = Keyword.get(url_config, :port, "80")
      path = Keyword.get(url_config, :path, "/")
      %ServerObject{
        url: "#{scheme}://#{host}:#{port}#{path}"
      }
    end
  end

  defmodule ContactObject do
    defstruct [
      :name,
      :url,
      :email
    ]
    @type t :: %__MODULE__{
      name: String.t,
      url: String.t,
      email: String.t
    }
  end

  defmodule InfoObject do
    alias PhoenixSwagger.OpenAPI.{ContactObject, LicenseObject}
    @enforce_keys [:title, :version]
    defstruct [
      :title,
      :description,
      :termsOfService,
      :contact,
      :license,
      :version
    ]
    @type t :: %__MODULE__{
      title: String.t,
      description: String.t,
      termsOfService: String.t,
      contact: ContactObject.t,
      license: LicenseObject.t,
      version: String.t
    }
  end

  defmodule OpenAPIObject do
    alias PhoenixSwagger.OpenAPI.{
      InfoObject, ServerObject, PathsObject, ComponentsObject,
      SecurityRequirementObject, TagObject, ExternalDocumentationObject
    }
    defstruct [
      :info,
      :servers,
      :paths,
      :components,
      :security,
      :tags,
      :externalDocs,
      openapi: "3.0",
    ]
    @type t :: %OpenAPIObject{
      openapi: String.t,
      info: InfoObject.t,
      servers: [ServerObject.t],
      paths: PathsObject.t,
      components: ComponentsObject.t,
      security: [SecurityRequirementObject.t],
      tags: [TagObject.t],
      externalDocs: ExternalDocumentationObject.t
    }
  end

  defmodule LicenseObject do
    defstruct [
      :name,
      :url
    ]
    @type t :: %__MODULE__{
      name: String.t,
      url: String.t
    }
  end

  defmodule ServerVariableObject do
    defstruct [
      :enum,
      :default,
      :description
    ]
    @type t :: %{
      enum: [String.t],
      default: String.t,
      description: String.t
    }
  end

  defmodule ComponentsObject do
    alias PhoenixSwagger.OpenAPI.{
      SchemaObject, ReferenceObject, ResponseObject, ParameterObject, ExampleObject,
      RequestBodyObject, HeaderObject, SecuritySchemeObject, LinkObject, CallbackObject
    }
    defstruct [
      :schemas,
      :responses,
      :parameters,
      :examples,
      :requestBodies,
      :headers,
      :securitySchemes,
      :links,
      :callbacks,
    ]
    @type t :: %{
      schemas: %{String.t => SchemaObject.t | ReferenceObject.t},
      responses: %{String.t =>  ResponseObject.t | ReferenceObject.t},
      parameters: %{String.t =>  ParameterObject.t | ReferenceObject.t},
      examples: %{String.t => ExampleObject.t | ReferenceObject.t},
      requestBodies: %{String.t => RequestBodyObject.t | ReferenceObject.t},
      headers: %{String.t =>  HeaderObject.t | ReferenceObject.t},
      securitySchemes: %{String.t =>  SecuritySchemeObject.t | ReferenceObject.t},
      links: %{String.t => LinkObject.t | ReferenceObject.t},
      callbacks: %{String.t => CallbackObject.t | ReferenceObject.t}
    }
  end

  defmodule PathsObject do
    alias PhoenixSwagger.OpenAPI.PathItemObject

    @type t :: %{String.t => PathItemObject.t}

    @doc """
    Create a PathsObject map from the routes in the given router module.
    """
    @spec from_router(module) :: t
    def from_router(router) do
      router.__routes__()
      |> Enum.group_by(fn route -> route.path end)
      |> Enum.map(fn {k, v} -> {open_api_path(k), PathItemObject.from_routes(v)} end)
      |> Enum.filter(fn {_k, v} -> !is_nil(v) end)
      |> Map.new()
    end

    @spec open_api_path(String.t) :: String.t
    defp open_api_path(path) do
      path
      |> String.split("/")
      |> Enum.map(fn ":"<>segment -> "{#{segment}}"; segment -> segment end)
      |> Enum.join("/")
    end
  end

  defmodule PathItemObject do
    alias PhoenixSwagger.OpenAPI.{OperationObject, ServerObject, ParameterObject, ReferenceObject}
    defstruct [
      :"$ref",
      :summary,
      :description,
      :get,
      :put,
      :post,
      :delete,
      :options,
      :head,
      :patch,
      :trace,
      :servers,
      :parameters
    ]
    @type t :: %__MODULE__{
      "$ref": String.t,
      summary: String.t,
      description: String.t,
      get: OperationObject.t,
      put: OperationObject.t,
      post: OperationObject.t,
      delete: OperationObject.t,
      options: OperationObject.t,
      head: OperationObject.t,
      patch: OperationObject.t,
      trace: OperationObject.t,
      servers: [ServerObject.t],
      parameters: [ParameterObject.t | ReferenceObject.t]
    }

    @type route :: %{verb: atom, plug: atom, opts: any}

    @doc """
    Builds a PathItemObject struct from a list of routes that share a path.
    """
    @spec from_routes([route]) :: nil | t
    def from_routes(routes) do
      routes
      |> Enum.filter(&function_exported?(&1.plug, :open_api_operation, 1))
      |> from_valid_routes()
    end

    @spec from_valid_routes([route]) :: nil | t
    defp from_valid_routes([]), do: nil
    defp from_valid_routes(routes) do
      Enum.reduce(routes, %PathItemObject{}, fn route, path_item ->
        Map.put(path_item, route.verb, OperationObject.from_route(route))
      end)
    end
  end

  defmodule ResponseObject do
    alias PhoenixSwagger.OpenAPI.{HeaderObject, ReferenceObject, MediaTypeObject, LinkObject}
    defstruct [
      :description,
      :headers,
      :content,
      :links
    ]
    @type t :: %__MODULE__{
      description: String.t,
      headers: %{String.t => HeaderObject.t | ReferenceObject.t},
      content: %{String.t => MediaTypeObject.t},
      links: %{String.t => LinkObject.t | ReferenceObject.t}
    }
  end

  defmodule MediaTypeObject do
    alias PhoenixSwagger.OpenAPI.{SchemaObject, ReferenceObject, ExampleObject, EncodingObject}
    defstruct [
      :schema,
      :example,
      :examples,
      :encoding
    ]
    @type t :: %__MODULE__{
      schema: SchemaObject.t | ReferenceObject.t,
      example: any,
      examples: %{String.t => ExampleObject.t | ReferenceObject.t},
      encoding: %{String => EncodingObject.t}
    }
  end

  defmodule ReferenceObject do
    defstruct [
      :"$ref"
    ]
    @type t :: %{
      "$ref": String.t
    }
  end

  defmodule RequestBodyObject do
    alias PhoenixSwagger.OpenAPI.MediaTypeObject
    defstruct [
      :description,
      :content,
      :required
    ]
    @type t :: %__MODULE__{
      description: String.t,
      content: %{String.t => MediaTypeObject.t},
      required: boolean
    }
  end


  defmodule OperationObject do
    alias PhoenixSwagger.OpenAPI.{
      ExternalDocumentationObject, ParameterObject, ReferenceObject,
      RequestBodyObject, ResponsesObject, CallbackObject,
      SecurityRequirementObject, ServerObject
    }
    defstruct [
      :tags,
      :summary,
      :description,
      :externalDocs,
      :operationId,
      :parameters,
      :requestBody,
      :responses,
      :callbacks,
      :deprecated,
      :security,
      :servers
    ]
    @type t :: %__MODULE__{
      tags: [String.t],
      summary: String.t,
      description: String.t,
      externalDocs: ExternalDocumentationObject.t,
      operationId: String.t,
      parameters: [ParameterObject.t | ReferenceObject.t],
      requestBody: [RequestBodyObject.t | ReferenceObject.t],
      responses: ResponsesObject.t,
      callbacks: %{
        String.t => CallbackObject.t | ReferenceObject.t
      },
      deprecated: boolean,
      security: [SecurityRequirementObject.t],
      servers: [ServerObject.t]
    }

    @doc """
    Constructs an OperationObject struct from the plug and opts specified in the given route
    """
    @spec from_route(PathItemObject.route) :: t
    def from_route(route) do
      from_plug(route.plug, route.opts)
    end

    @doc """
    Constructs an OperationObject struct from plug module and opts
    """
    @spec from_plug(module, any) :: t
    def from_plug(plug, opts) do
      plug.open_api_operation(opts)
    end

    @doc """
    Shorthand for constructing a ParameterObject name, location, type, description and optional examples
    """
    @spec parameter(String.t, String.t, String.t, keyword) :: RequestBodyObject.t
    def parameter(name, location, type, description, opts \\ []) do
      params =
        [name: name, in: location, description: description, required: location == :path]
        |> Keyword.merge(opts)

      ParameterObject
      |> struct(params)
      |> ParameterObject.put_schema(type)
    end

    @doc """
    Shorthand for constructing a RequestBodyObject with description, media_type, schema and optional examples
    """
    @spec request_body(String.t, String.t, String.t, keyword) :: RequestBodyObject.t
    def request_body(description, media_type, schema_ref, opts \\ []) do
      %RequestBodyObject{
        description: description,
        content: %{
          media_type => %MediaTypeObject{
            schema: schema_ref,
            example: opts[:example],
            examples: opts[:examples]
          }
        }
      }
    end

    @doc """
    Shorthand for constructing a ResponseObject with description, media_type, schema and optional examples
    """
    @spec response(String.t, String.t, String.t, keyword) :: ResponseObject.t
    def response(description, media_type, schema_ref, opts \\ []) do
      %ResponseObject{
        description: description,
        content: %{
          media_type => %MediaTypeObject {
            schema: schema_ref,
            example: opts[:example],
            examples: opts[:examples]
          }
        }
      }
    end
  end

  defmodule ExternalDocumentationObject do
    defstruct [
      :description,
      :url
    ]
    @type t :: %__MODULE__{
      description: String.t,
      url: String.t
    }
  end

  defmodule SchemaObject do
    alias PhoenixSwagger.OpenAPI.{
      SchemaObject, ReferenceObject, DiscriminatorObject, XmlObject, ExternalDocumentationObject
    }
    defstruct [
      :title,
      :multipleOf,
      :maximum,
      :exclusiveMaximum,
      :minimum,
      :exclusiveMinimum,
      :maxLength,
      :minLength,
      :pattern,
      :maxItems,
      :minItems,
      :uniqueItems,
      :maxProperties,
      :minProperties,
      :required,
      :enum,
      :type,
      :allOf,
      :oneOf,
      :anyOf,
      :not,
      :items,
      :properties,
      :additionalProperties,
      :description,
      :format,
      :default,
      :nullable,
      :discriminator,
      :readOnly,
      :writeOnly,
      :xml,
      :externalDocs,
      :example,
      :deprecated
    ]
    @type t :: %__MODULE__{
      title: String.t,
      multipleOf: number,
      maximum: number,
      exclusiveMaximum: number,
      minimum: number,
      exclusiveMinimum: number,
      maxLength: integer,
      minLength: integer,
      pattern: String.t,
      maxItems: integer,
      minItems: integer,
      uniqueItems: boolean,
      maxProperties: integer,
      minProperties: integer,
      required: [String.t],
      enum: [String.t],
      type: String.t,
      allOf: [SchemaObject.t | ReferenceObject.t],
      oneOf: [SchemaObject.t | ReferenceObject.t],
      anyOf: [SchemaObject.t | ReferenceObject.t],
      not: SchemaObject.t | ReferenceObject.t,
      items: SchemaObject.t | ReferenceObject.t,
      properties: %{String.t => SchemaObject.t | ReferenceObject.t},
      additionalProperties: boolean | SchemaObject.t | ReferenceObject.t,
      description: String.t,
      format: String.t,
      default: any,
      nullable: boolean,
      discriminator: DiscriminatorObject.t,
      readOnly: boolean,
      writeOnly: boolean,
      xml: XmlObject.t,
      externalDocs: ExternalDocumentationObject.t,
      example: any,
      deprecated: boolean
    }
  end

  defmodule ParameterObject do
    alias PhoenixSwagger.OpenAPI.{
      SchemaObject, ReferenceObject, ExampleObject, MediaTypeObject
    }
    defstruct [
      :name,
      :in,
      :description,
      :required,
      :deprecated,
      :allowEmptyValue,
      :style,
      :explode,
      :allowReserved,
      :schema,
      :example,
      :examples,
      :content,
    ]
    @type style :: :matrix | :label | :form | :simple | :spaceDelimited | :pipeDelimited | :deepObject
    @type t :: %__MODULE__{
      name: String.t,
      in: :query | :header | :path | :cookie,
      description: String.t,
      required: boolean,
      deprecated: boolean,
      allowEmptyValue: boolean,
      style: style,
      explode: boolean,
      allowReserved: boolean,
      schema: SchemaObject.t | ReferenceObject.t,
      example: any,
      examples: %{String.t => ExampleObject.t | ReferenceObject.t},
      content: %{String.t => MediaTypeObject.t}
    }

    @doc """
    Sets the schema for a parameter from a simple type, reference or SchemaObject
    """
    @spec put_schema(t, ReferenceObject.t | SchemaObject.t | atom | String.t) :: t
    def put_schema(parameter = %ParameterObject{}, type = %ReferenceObject{}) do
      %{parameter | schema: type}
    end
    def put_schema(parameter = %ParameterObject{}, type = %SchemaObject{}) do
      %{parameter | schema: type}
    end
    def put_schema(parameter = %ParameterObject{}, type) when is_binary(type) or is_atom(type) do
      %{parameter | schema: %SchemaObject{type: type}}
    end
  end

  defmodule EncodingObject do
    alias PhoenixSwagger.OpenAPI.{HeaderObject, ReferenceObject, ParameterObject}
    defstruct [
      :contentType,
      :headers,
      :style,
      :explode,
      :allowReserved
    ]
    @type t :: %__MODULE__{
      contentType: String.t,
      headers: %{String.t => HeaderObject.t | ReferenceObject.t},
      style: ParameterObject.style,
      explode: boolean,
      allowReserved: boolean
    }
  end

  defmodule ResponsesObject do
    alias PhoenixSwagger.OpenAPI.{ResponseObject, ReferenceObject}
    @type t :: %{
      :default => ResponseObject.t | ReferenceObject.t,
      integer => ResponseObject.t | ReferenceObject.t
    }
  end

  defmodule CallbackObject do
    alias PhoenixSwagger.OpenAPI.PathItemObject
    @type t :: %{
      String.t => PathItemObject.t
    }
  end

  defmodule ExampleObject do
    defstruct [
      :summary,
      :description,
      :value,
      :externalValue
    ]
    @type t :: %{
      summary: String.t,
      description: String.t,
      value: any,
      externalValue: String.t
    }
  end

  defmodule LinkObject do
    alias PhoenixSwagger.OpenAPI.ServerObject
    defstruct [
      :operationRef,
      :operationId,
      :parameters,
      :requestBody,
      :description,
      :server
    ]
    @type t :: %{
      operationRef: String.t,
      operationId: String.t,
      parameters: %{String.t => any},
      requestBody: any,
      description: String.t,
      server: ServerObject.t
    }
  end

  defmodule HeaderObject do
    alias PhoenixSwagger.OpenAPI.{SchemaObject, ReferenceObject, ExampleObject}
    defstruct [
      :description,
      :required,
      :deprecated,
      :allowEmptyValue,
      :explode,
      :schema,
      :example,
      :examples,
      style: :simple
    ]
    @type t :: %__MODULE__{
      description: String.t,
      required: boolean,
      deprecated: boolean,
      allowEmptyValue: boolean,
      style: :simple,
      explode: boolean,
      schema: SchemaObject.t | ReferenceObject.t,
      example: any,
      examples: %{String.t => ExampleObject.t | ReferenceObject.t}
    }
  end

  defmodule TagObject do
    alias PhoenixSwagger.OpenAPI.ExternalDocumentationObject
    defstruct [
      :name,
      :description,
      :externalDocs
    ]
    @type t :: %{
      name: String.t,
      description: String.t,
      externalDocs: ExternalDocumentationObject.t
    }
  end

  defmodule DiscriminatorObject do
    defstruct [
      :propertyName,
      :mapping
    ]
    @type t :: %__MODULE__{
      propertyName: String.t,
      mapping: %{String.t => String.t}
    }
  end

  defmodule XmlObject do
    defstruct [
      :name,
      :namespace,
      :prefix,
      :attribute,
      :wrapped
    ]
    @type t :: %__MODULE__{
      name: String.t,
      namespace: String.t,
      prefix: String.t,
      attribute: boolean,
      wrapped: boolean
    }
  end

  defmodule SecuritySchemeObject do
    alias PhoenixSwagger.OpenAPI.OAuthFlowsObject
    defstruct [
      :type,
      :description,
      :name,
      :in,
      :scheme,
      :bearerFormat,
      :flows,
      :openIdConnectUrl
    ]
    @type t :: %__MODULE__{
      type: String.t,
      description: String.t,
      name: String.t,
      in: String.t,
      scheme: String.t,
      bearerFormat: String.t,
      flows: OAuthFlowsObject.t,
      openIdConnectUrl: String.t
    }
  end

  defmodule OAuthFlowsObject do
    alias PhoenixSwagger.OpenAPI.OAuthFlowObject
    defstruct [
      :implicit,
      :password,
      :clientCredentials,
      :authorizationCode
    ]
    @type t :: %__MODULE__{
      implicit: OAuthFlowObject.t,
      password: OAuthFlowObject.t,
      clientCredentials: OAuthFlowObject.t,
      authorizationCode: OAuthFlowObject.t
    }
  end

  defmodule OAuthFlowObject do
    defstruct [
      :authorizationUrl,
      :tokenUrl,
      :refreshUrl,
      :scopes
    ]
    @type t :: %__MODULE__{
      authorizationUrl: String.t,
      tokenUrl: String.t,
      refreshUrl: String.t,
      scopes: %{String.t => String.t}
    }
  end

  defmodule SecurityRequirementObject do
    @type t :: %{String.t => [String.t]}
  end

  def resolve_schema_modules(spec = %OpenAPIObject{}) do
    components = spec.components || %ComponentsObject{}
    schemas = components.schemas || %{}
    {paths, schemas} = resolve_schema_modules_from_paths(spec.paths, schemas)
    schemas = resolve_schema_modules_from_schemas(schemas)
    %{spec | paths: paths, components: %{components| schemas: schemas}}
  end
  def resolve_schema_modules_from_paths(paths = %{}, schemas = %{}) do
    Enum.reduce(paths, {paths, schemas}, fn {path, path_item}, {paths, schemas} ->
      {new_path_item, schemas} = resolve_schema_modules_from_path_item(path_item, schemas)
      {Map.put(paths, path, new_path_item), schemas}
    end)
  end
  def resolve_schema_modules_from_path_item(path = %PathItemObject{}, schemas) do
    path
    |> Map.from_struct()
    |> Enum.filter(fn {_k, v} -> match?(%OperationObject{}, v) end)
    |> Enum.reduce({path, schemas}, fn {k, operation}, {path, schemas} ->
      {new_operation, schemas} = resolve_schema_modules_from_operation(operation, schemas)
      {Map.put(path, k, new_operation), schemas}
    end)
  end
  def resolve_schema_modules_from_operation(operation = %OperationObject{}, schemas) do
    {parameters, schemas} = resolve_schema_modules_from_parameters(operation.parameters, schemas)
    {request_body, schemas} = resolve_schema_modules_from_request_body(operation.requestBody, schemas)
    {responses, schemas} = resolve_schema_modules_from_responses(operation.responses, schemas)
    new_operation = %{operation | parameters: parameters, requestBody: request_body, responses: responses}
    {new_operation, schemas}
  end
  def resolve_schema_modules_from_parameters(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_parameters(parameters, schemas) do
    {parameters, schemas} =
      Enum.reduce(parameters, {[], schemas}, fn parameter, {parameters, schemas} ->
        {new_parameter, schemas} = resolve_schema_modules_from_parameter(parameter, schemas)
        {[new_parameter | parameters], schemas}
      end)
    {Enum.reverse(parameters), schemas}
  end
  def resolve_schema_modules_from_parameter(parameter = %ParameterObject{schema: schema, content: nil}, schemas) when is_atom(schema) do
    new_parameter = %{parameter | schema: %ReferenceObject{"$ref": "#/components/schemas/#{schema}"}}
    new_schemas = Map.put(schemas, schema, schema.schema())
    {new_parameter, new_schemas}
  end
  def resolve_schema_modules_from_parameter(parameter = %ParameterObject{schema: nil, content: content = %{}}, schemas) do
    {new_content, schemas} = resolve_schema_modules_from_content(content, schemas)
    {%{parameter | content: new_content}, schemas}
  end
  def resolve_schema_modules_from_parameter(parameter = %ParameterObject{}, schemas) do
    {parameter, schemas}
  end
  def resolve_schema_modules_from_content(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_content(content, schemas) do
    Enum.reduce(content, {content, schemas}, fn {mime, media}, {content, schemas} ->
      {new_media, schemas} = resolve_schema_modules_from_media_type(media, schemas)
      {Map.put(content, mime, new_media), schemas}
    end)
  end
  def resolve_schema_modules_from_media_type(media = %MediaTypeObject{schema: schema}, schemas) when is_atom(schema) do
    new_media = %{media | schema: %ReferenceObject{"$ref": "#/components/schemas/#{schema}"}}
    new_schemas = Map.put(schemas, schema, schema.schema())
    {new_media, new_schemas}
  end
  def resolve_schema_modules_from_media_type(media = %MediaTypeObject{}, schemas) do
    {media, schemas}
  end
  def resolve_schema_modules_from_request_body(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_request_body(request_body = %RequestBodyObject{}, schemas) do
    {content, schemas} = resolve_schema_modules_from_content(request_body.content, schemas)
    new_request_body = %{request_body | content: content}
    {new_request_body, schemas}
  end
  def resolve_schema_modules_from_responses(responses = %{}, schemas = %{}) do
    Enum.reduce(responses, {responses, schemas}, fn {status, response}, {responses, schemas} ->
      {new_response, schemas} = resolve_schema_modules_from_response(response, schemas)
      {Map.put(responses, status, new_response), schemas}
    end)
  end
  def resolve_schema_modules_from_response(response = %ResponseObject{}, schemas = %{}) do
    {content, schemas} = resolve_schema_modules_from_content(response.content, schemas)
    new_response = %{response | content: content}
    {new_response, schemas}
  end
  def resolve_schema_modules_from_schemas(schemas = %{}) do
    Enum.reduce(schemas, schemas, fn {name, schema}, schemas ->
      {schema, schemas} = resolve_schema_modules_from_schema(schema, schemas)
      Map.put(schemas, name, schema)
    end)
  end
  def resolve_schema_modules_from_schema(false, schemas), do: {false, schemas}
  def resolve_schema_modules_from_schema(true, schemas), do: {true, schemas}
  def resolve_schema_modules_from_schema(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_schema(schema, schemas) when is_atom(schema) do
    new_schemas = cond do
      Map.has_key?(schemas, schema) ->
        schemas

      true ->
        {new_schema, schemas} = resolve_schema_modules_from_schema(schema.schema(), schemas)
        Map.put(schemas, schema, new_schema)
    end
    {%ReferenceObject{"$ref": "#/components/schemas/#{schema}"}, new_schemas}
  end
  def resolve_schema_modules_from_schema(schema = %SchemaObject{}, schemas) do
    {all_of, schemas} = resolve_schema_modules_from_schema(schema.allOf, schemas)
    {one_of, schemas} = resolve_schema_modules_from_schema(schema.oneOf, schemas)
    {any_of, schemas} = resolve_schema_modules_from_schema(schema.anyOf, schemas)
    {not_schema, schemas} = resolve_schema_modules_from_schema(schema.not, schemas)
    {items, schemas} = resolve_schema_modules_from_schema(schema.items, schemas)
    {additional, schemas} = resolve_schema_modules_from_schema(schema.additionalProperties, schemas)
    {properties, schemas} = resolve_schema_modules_from_schema_properties(schema.properties, schemas)
    schema =
      %{schema |
        allOf: all_of,
        oneOf: one_of,
        anyOf: any_of,
        not: not_schema,
        items: items,
        additionalProperties: additional,
        properties: properties
      }
    {schema, schemas}
  end
  def resolve_schema_modules_from_schema(ref = %ReferenceObject{}, schemas), do: {ref, schemas}
  def resolve_schema_modules_from_schema_properties(nil, schemas), do: {nil, schemas}
  def resolve_schema_modules_from_schema_properties(properties, schemas) do
    Enum.reduce(properties, {properties, schemas}, fn {name, property}, {properties, schemas} ->
      {new_property, schemas} = resolve_schema_modules_from_schema(property, schemas)
      {Map.put(properties, name, new_property), schemas}
    end)
  end

  def to_json(value = %{__struct__: _}) do
    value
    |> Map.from_struct()
    |> to_json()
  end
  def to_json(value) when is_map(value) do
    value
    |> Enum.map(fn {k,v} -> {to_string(k), to_json(v)} end)
    |> Enum.filter(fn {_, :null} -> false; _ -> true end)
    |> Enum.into(%{})
  end
  def to_json(value) when is_list(value) do
    Enum.map(value, &to_json/1)
  end
  def to_json(nil) do :null end
  def to_json(:null) do :null end
  def to_json(true) do true end
  def to_json(false) do false end
  def to_json(value) when is_atom(value) do to_string(value) end
  def to_json(value) do value end
end