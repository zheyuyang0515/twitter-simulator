defmodule Proj4.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Proj4.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Proj4Web.Endpoint, []),
      # Start your own worker by calling: Proj4.Worker.start_link(arg1, arg2, arg3)
      # worker(Proj4.Worker, [arg1, arg2, arg3]),
    ]
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Proj4.Supervisor]
    Supervisor.start_link(children, opts)
    children = [
      %{
        id: ClientSupervisor,
        start: {ClientSupervisor, :start_link, []}
      }
    ]
    Supervisor.start_link(children, strategy: :one_for_all)
    children_server = [
      # The Stack is a child started via Stack.start_link([:hello])
      %{
        id: :server,
        start: {Server, :start_link, []}
      }
    ]
    {:ok, _} = Supervisor.start_link(children_server, strategy: :one_for_one)
    Server.init_db()
    num_user = "10000"
    num_msg = "10000"
    list = []
    list = Enum.map(0..String.to_integer(num_user) - 1, fn _ ->
      pid = ClientSupervisor.add(num_msg, String.to_integer(num_user))
      list ++ pid
    end)
    Enum.map(0..length(list) - 1, fn i ->
      pid = Enum.at(list, i)
      GenServer.cast(pid, {:start_login, i, :new})
    end)

    {:ok, self()}
  end
  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Proj4Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
