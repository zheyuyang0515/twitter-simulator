defmodule Proj4Web.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end
  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
  def handle_in("registration", payload, socket) do
    username = payload["username"]
    password = payload["password"]
    result = GenServer.call(:server, {:registration, username, password})
    if result == :success do
      {:reply, :register_success, socket}
    else
      {:reply, :register_failed, socket}
    end
  end
  def handle_in("login", payload, socket) do
    username = payload["username"]
    password = payload["password"]
    result = GenServer.call(:server, {:login, username, password, 1, socket})
    case result do
      :username_not_exist -> {:reply, {:username_not_exist, %{}}, socket}
      :password_incorrect -> {:reply, {:password_incorrect, %{}}, socket}
      :login_repeat -> {:reply, {:login_repeat, %{}}, socket}
      :success -> {:reply, {:success, %{username: username, password: password}}, socket}
    end
  end
  def handle_in("logout", payload, socket) do
    username = payload["username"]
    result = GenServer.call(:server, {:logout, username, 1})
    case result do
      :user_offline -> {:reply, :user_offline, socket}
      :invalid_request -> {:reply, :invalid_request, socket}
      :success -> {:reply, :success, socket}
    end
  end
  def handle_in("delete_account", payload, socket) do
    username = payload["username"]
    password = payload["password"]
    result = GenServer.call(:server, {:delete_account, username, password})
    case result do
      :username_not_exist -> {:reply, :username_not_exist, socket}
      :password_incorrect -> {:reply, :password_incorrect, socket}
      :success -> {:reply, :success, socket}
    end
  end
  def handle_in("subscribe", payload, socket) do
    username = payload["username"]
    target_username = payload["target_username"]
    {result, target_socket} = GenServer.call(:server, {:subscribe, username, 1, target_username})
    case result do
      :invalid_request -> {:reply, :invalid_request, socket}
      :user_not_exist -> {:reply, :user_not_exist, socket}
      :success -> if (target_socket != nil) do
        push(target_socket, "new_subscriber", %{username: username})
      end
      {:reply, :success, socket}
    end
  end
  def handle_in("send_tweet", payload, socket) do
    username = payload["username"]
    content = payload["content"]
    hashtags = String.split(payload["hashtags"], ";")
    mentions = String.split(payload["mentions"], ";")
    result = GenServer.call(:server, {:send_tweet, username, 1, content, hashtags, mentions})
    case result do
      {:invalid_request, _, _} -> {:reply, :invalid_request, socket}
      {:success, sockets_subscribes, sockets_mentions, tweet_id} ->
        Enum.map(sockets_subscribes, fn id ->
        push(id, "auto_subscribed_tweet", %{username: username, tweet_id: tweet_id, content: content, hashtags: hashtags, mentions: mentions})
      end)
      Enum.map(sockets_mentions, fn id ->
        push(id, "auto_mentioned_tweet", %{username: username, tweet_id: tweet_id, content: content, hashtags: hashtags, mentions: mentions})
      end)
      {:reply, :success, socket}
    end
  end
  def handle_in("retweet", payload, socket) do
    username = payload["username"]
    tweet_id = payload["tweet_id"]
    comments = payload["comments"]
    result = GenServer.call(:server, {:retweet, tweet_id, comments, username, 1})
    case result do
      {:invalid_request, _, _, _, _} -> {:reply, {:invalid_request, %{}}, socket}
      {:user_not_exist, _, _, _, _} -> {:reply, {:user_not_exist, %{}}, socket}
      {:success, sockets_subscribes, tweet_id, source_user, content} ->
        Enum.map(sockets_subscribes, fn id ->
        push(id, "auto_subscribed_retweet", %{username: username, tweet_id: tweet_id, content: content, source_user: source_user, comments: comments})
      end)
      {:reply, {:success, %{source_user: source_user, content: content, comments: comments}}, socket}
    end
  end
  def handle_in("query_hashtag", payload, socket) do
    username = payload["username"]
    hashtag = payload["hashtag"]
    result = GenServer.call(:server, {:query_hashtag, username, 1, hashtag})
    case result do
      :invalid_request -> {:reply, {:invalid_request, %{}}, socket}
      {:success, result} ->
        map = %{"tweet_id" => [], "sender_username" => [], "content" => [], "source_username" => [], "comment" => []}
        if(length(result) == 0) do
          {:reply, {:success, %{result: map}}, socket}
        else
          IO.inspect(result)
          map = Enum.map(result, fn tweet ->
            {tweet_id, sender_username, content, source_username, comment, is_new} = tweet
            map = if is_new == :new_tweet do
              Map.put(map, "comment", Map.get(map, "comment") ++ nil)
            else
              if comment == nil do
                Map.put(map, "comment", Map.get(map, "comment") ++ nil)
              else
                Map.put(map, "comment", Map.get(map, "comment") ++ comment)
              end
            end
            map = Map.put(map, "tweet_id", Map.get(map, "tweet_id") ++ tweet_id)
            map = Map.put(map, "sender_username", Map.get(map, "sender_username") ++ sender_username)
            map = Map.put(map, "content", Map.get(map, "content") ++ content)
            map = Map.put(map, "source_username", Map.get(map, "source_username") ++ source_username)
            map
          end)
          {:reply, {:success, %{result: map}}, socket}
        end
    end
  end
  def handle_in("query_mentioned", payload, socket) do
    username = payload["username"]
    result = GenServer.call(:server, {:query_mentions, username, 1})
    case result do
      :invalid_request -> {:reply, {:invalid_request, %{}}, socket}
      {:success, result} ->
        map = %{"tweet_id" => [], "sender_username" => [], "content" => [], "source_username" => [], "comment" => []}
        if(length(result) == 0) do
          {:reply, {:success, %{result: map}}, socket}
        else
          IO.inspect(result)
          map = Enum.map(result, fn tweet ->
            {tweet_id, sender_username, content, source_username, comment, is_new} = tweet
            map = if is_new == :new_tweet do
              Map.put(map, "comment", Map.get(map, "comment") ++ nil)
            else
              if comment == nil do
                Map.put(map, "comment", Map.get(map, "comment") ++ nil)
              else
                Map.put(map, "comment", Map.get(map, "comment") ++ comment)
              end
            end
            map = Map.put(map, "tweet_id", Map.get(map, "tweet_id") ++ tweet_id)
            map = Map.put(map, "sender_username", Map.get(map, "sender_username") ++ sender_username)
            map = Map.put(map, "content", Map.get(map, "content") ++ content)
            map = Map.put(map, "source_username", Map.get(map, "source_username") ++ source_username)
            map
          end)
          {:reply, {:success, %{result: map}}, socket}
        end
    end
  end
  def handle_in("query_subscribed", payload, socket) do
    username = payload["username"]
    result = GenServer.call(:server, {:query_subscribe, username, 1})
    case result do
      :invalid_request -> {:reply, {:invalid_request, %{}}, socket}
      {:success, result} ->
        map = %{"tweet_id" => [], "sender_username" => [], "content" => [], "source_username" => [], "comment" => []}
        if(length(result) == 0) do
          {:reply, {:success, %{result: map}}, socket}
        else
          IO.inspect(result)
          map = Enum.map(result, fn tweet ->
            {tweet_id, sender_username, content, source_username, comment, is_new} = tweet
            map = if is_new == :new_tweet do
              Map.put(map, "comment", Map.get(map, "comment") ++ nil)
            else
              if comment == nil do
                Map.put(map, "comment", Map.get(map, "comment") ++ nil)
              else
                Map.put(map, "comment", Map.get(map, "comment") ++ comment)
              end
            end
            map = Map.put(map, "tweet_id", Map.get(map, "tweet_id") ++ tweet_id)
            map = Map.put(map, "sender_username", Map.get(map, "sender_username") ++ sender_username)
            map = Map.put(map, "content", Map.get(map, "content") ++ content)
            map = Map.put(map, "source_username", Map.get(map, "source_username") ++ source_username)
            map
          end)
          {:reply, {:success, %{result: map}}, socket}
        end
    end
  end
end
