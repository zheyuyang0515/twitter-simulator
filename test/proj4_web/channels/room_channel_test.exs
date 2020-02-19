defmodule Proj4Web.RoomChannelTest do
  use Proj4Web.ChannelCase

  alias Proj4Web.RoomChannel

  setup do
    socket_list = []
    socket_list = Enum.map(0..99, fn _ ->
      {:ok, _, socket} =
      socket("user_id", %{some: :assign})
        |> subscribe_and_join(RoomChannel, "room:lobby")
        socket_list ++ socket
    end)
    list = []
    list = Enum.map(0..99, fn username ->
      {:ok, pid} = User.start_link(Integer.to_string(username), Integer.to_string(username), Enum.at(socket_list, username), 100)
      list ++ pid
    end)
    {:ok, %{socket_list: socket_list, list: list}}
  end

  @tag :simulation
  test "100 users simulation", %{socket_list: socket_list, list: list} do
    Enum.map(list, fn id ->
      GenServer.cast(id, :start)
    end)
  end




end
