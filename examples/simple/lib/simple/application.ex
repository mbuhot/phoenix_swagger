defmodule Simple.Application do
  use Application
  import Supervisor.Spec, only: [supervisor: 2]

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do

    # PhoenixSwagger.Validator.parse_swagger_schema("priv/static/swagger.json")

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Simple.Repo, []),
      # Start the endpoint when the application starts
      supervisor(SimpleWeb.Endpoint, []),
      # Start your own worker by calling: Simple.Worker.start_link(arg1, arg2, arg3)
      # worker(Simple.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Simple.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SimpleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
