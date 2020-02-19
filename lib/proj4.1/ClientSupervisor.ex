defmodule ClientSupervisor do
  use DynamicSupervisor
  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  @spec init(:no_args) ::
          {:ok,
           %{
             extra_arguments: [any],
             intensity: non_neg_integer,
             max_children: :infinity | non_neg_integer,
             period: pos_integer,
             strategy: :one_for_one
           }}
  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add(tweet_sent, num_user) do
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, {Client, {String.to_integer(tweet_sent), num_user}})
    pid
  end
end
