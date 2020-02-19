defmodule Client do
  use GenServer
  def start_link({actions, num_user}) do
    GenServer.start_link(__MODULE__, {actions, num_user})
  end
  def init({actions, num_user}), do: {:ok, {nil, nil, %{}, :offline, actions, 0, num_user, [], 0}}
  def send_msg(pid, content) do
    GenServer.cast(pid, content)
  end
  def login(username, password, pid) do
    result = Server.send_msg(:server, {:login, username, password, pid, 1})
    case result do
      :success -> send_msg(pid, :login_success)
      :username_not_exist -> IO.puts("Sorry! This username is not exist, please try again.")
      :password_incorrect -> IO.puts("Sorry! The password is incorrect, please try again.")
      :login_repeat -> IO.puts("Sorry! This user is already online.")
    end
  end
  def retweet(username, pid, tweet_id, source_username, content, comment) do
    result = Server.send_msg(:server, {:retweet, tweet_id, comment, username, pid})
    {result, _, _, _, _} = result
    case result do
      :invalid_request -> IO.puts("Invalid Logout Request: Unauthorized action!")
      :success -> if comment == nil do
        IO.puts("Retweet send successfully! " <> username <> "(Forward: " <> source_username <> "): " <> content)
      else
        IO.puts("Retweet send successfully! " <> username <> "(Forward: " <> source_username <> "): " <> content <> " Comment: " <> comment)
      end
    end
  end
  def idle_wait(pid, id) do
    Process.sleep(100)
    rand = Enum.random(0..99)
    if rand < 50 do
      idle_wait(pid, id)
    else
      send_msg(pid, {:start_login, id, :old})
    end
  end
  def logout(username, pid) do
    result = Server.send_msg(:server, {:logout, username, pid})
    case result do
      :user_offline -> IO.puts("The user is offline")
      :invalid_request -> IO.puts("Invalid Logout Request: token not match")
      :success -> send_msg(pid, :logout_success)
    end
  end
  def register(username, password, pid) do
    result = Server.send_msg(:server, {:registration, username, password})
    case result do
      :failed -> IO.puts("Sorry! This username is already exist, please change another one.")
      :success -> send_msg(pid, {:register_success, username, password})
    end
  end
  def delete_account(username, password, pid) do
    result = Server.send_msg(:server, {:delete_account, username, password})
    case result do
      :username_not_exist -> IO.puts("Sorry! This username is not exist, please try again.")
      :password_incorrect -> IO.puts("Sorry! The password is incorrect, please try again.")
      :success -> send_msg(pid, {:delete_success, username, password})
    end
  end
  def subscribe(username, target_username, pid) do
    result = Server.send_msg(:server, {:subscribe, username, pid, target_username})
    {result, _} = result
    case result do
      :invalid_request -> IO.puts("Invalid Request: unauthorized request.")
      :user_not_exist -> IO.puts("Subscribe error: user not exist")
      :success -> IO.puts("Subscribe \""<> target_username <>"\" successfully!" )
    end
  end
  def send_tweet(username, content, hashtags, mentions, pid) do
    result = Server.send_msg(:server, {:send_tweet, username, pid, content, hashtags, mentions})
    {result, _, _, _} = result
    case result do
      :success -> IO.puts("Send tweet successfully: " <> content)
    end
  end
  def query_mentioned(username, pid) do
    result = Server.send_msg(:server, {:query_mentions, username, pid})
    if result == :invalid_request do
      IO.puts("Invalid Request: unauthorized request.")
    else
      {:success, result} = result
      list = []
      list = Enum.map(result, fn tweet ->
        {tweet_id, sender_username, content, _, _, _} = tweet
        IO.puts(sender_username <> ": " <> content)
        list ++ {tweet_id, sender_username, content}
      end)
      send_msg(pid, {:query_handler, list})
    end
  end
  def query_hashtag(username, hashtag, pid) do
    result = Server.send_msg(:server, {:query_hashtag, username, pid, hashtag})
    if result == :invalid_request do
      IO.puts("Invalid Request: unauthorized request.")
    else
      {:success, result} = result
      list = []
      list = Enum.map(result, fn tweet ->
        {tweet_id, sender_username, content, _, _, _} = tweet
        IO.puts(sender_username <> ": " <> content)
        list ++ {tweet_id, sender_username, content}
      end)
      send_msg(pid, {:query_handler, list})
    end
  end
  def query_subscribe(username, pid) do
    result = Server.send_msg(:server, {:query_subscribe, username, pid})
    if result == :invalid_request do
      IO.puts("Invalid Request: unauthorized request.")
    else
      {:success, result} = result
      list = []
      list = Enum.map(result, fn tweet ->
        {tweet_id, sender_username, content, source_username, comment, is_new} = tweet
        if is_new == :new_tweet do
          IO.puts(sender_username <> ": " <> content)
        else
          if comment == nil do
            IO.puts(sender_username <> "(Forward: " <> source_username <> "): " <> content)
          else
            IO.puts(sender_username <> "(Forward: " <> source_username <> "): " <> content <> " Comment: " <> comment)
          end
        end
        list ++ {tweet_id, sender_username, content}
      end)
      send_msg(pid, {:query_handler, list})
    end
  end
  def handle_cast(:new_subscriber, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    {:noreply, {username, password, tweet_list, state, actions, subscribers + 1, num_user, subscribed, tweet_sent}}
  end
  def handle_cast({:start_login, id, is_new}, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    if username == nil do
      new_username = to_string(id)
      new_password = "Client#" <> to_string(id)
      register(new_username, new_password, self())
      send_msg(self(), {:start_login, id, :new})
      {:noreply, {new_username, new_password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}}
    else
      login(username, password, self())
      subscribed = if is_new == :new do
        Enum.map(0..String.to_integer(username) - 1, fn target_username ->
          subscribe(username, to_string(target_username), self())
          subscribed ++ List.wrap(to_string(target_username))
        end)
      else
        subscribed
      end
      send_msg(self(), {:start, id})
      {:noreply, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}}
    end
  end
  #random choose next request
  def handle_cast({:start, id}, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    if actions <= 0 do
      {:noreply, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}}
    else
      now_prob = 1 / (String.to_integer(username) + 1)
      random = Enum.random(1..100)
      tweet_sent = if random <= now_prob * 100 do
        {send_content, send_hashtags, send_mentions} = Helper.create_tweet(username, num_user)
        send_tweet(username, send_content, send_hashtags, send_mentions, self())
        tweet_sent + 1
      else
        if map_size(tweet_list) != 0 do
           {_, {tweet_id, sender_username, content}} = Enum.random(tweet_list)
           comment = "Forward by Client#" <> username
           retweet(username, self(), tweet_id, sender_username, content, comment)
        end
        tweet_sent
      end
      rand = Enum.random(1..100)
      if rand <= 20 do
        logout(username, self())
        idle_wait(self(), id)
      else
        send_msg(self(), {:start, id})
      end
      {:noreply, {username, password, tweet_list, state, actions - 1, subscribers, num_user, subscribed, tweet_sent}}
    end
  end
  def handle_cast({:subscribed_tweet, tweet_id, sender_username, content, source_username, comment, is_new}, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    if is_new == :new_tweet do
      IO.puts(sender_username <> ": " <> content)
    else
      if comment == nil do
        IO.puts(sender_username <> "(Forward: " <> source_username <> "): " <> content)
      else
        IO.puts(sender_username <> "(Forward: " <> source_username <> "): " <> content <> " Comment: " <> comment)
      end
    end
    {:noreply, {username, password, Map.put(tweet_list, tweet_id, {tweet_id, sender_username, content}), state, actions, subscribers, num_user, subscribed, tweet_sent}}
  end

  def handle_cast({:mentioned_tweet, tweet_id, sender_username, content, _, _, _}, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    IO.puts(sender_username <> ": " <> content)
    {:noreply, {username, password, Map.put(tweet_list, tweet_id, {tweet_id, sender_username, content}), state, actions, subscribers, num_user, subscribed, tweet_sent}}
  end

  def handle_cast({:query_handler, list}, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    tweet_list = Enum.map(list, fn item ->
      {tweet_id, _, _} = item
      if Map.has_key?(tweet_list, tweet_id) == true do
        tweet_list
      else
        Map.put(tweet_list, tweet_id, item)
      end
    end)
    {:noreply, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}}
  end
  def handle_cast({:delete_success, username, _}, {_, _, tweet_list, _, actions, subscribers, num_user, subscribed, tweet_sent}) do
    IO.puts("The account " <> username <> " has been deleted. The tweets sent by this account are invisible to other users.")
    {:noreply, {nil, nil, tweet_list, :offline, actions, subscribers, num_user, subscribed, tweet_sent}}
  end
  def handle_cast({:register_success, username, password}, {_, _, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    IO.puts("Congratulations! The registration is successful.")
    IO.puts("Please remember your username: " <> username <> ".")
    {:noreply, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}}
  end
  def handle_cast(:login_success, {username, password, tweet_list, _, actions, subscribers, num_user, subscribed, tweet_sent}) do
    IO.puts("Login Success! Welcome back: " <> username <> "!")
    {:noreply, {username, password, tweet_list, :online, actions, subscribers, num_user, subscribed, tweet_sent}}
  end
  def handle_cast(:logout_success, {username, password, tweet_list, _, actions, subscribers, num_user, subscribed, tweet_sent}) do
    IO.puts("Logout Successful.")
    {:noreply, {username, password, tweet_list, :offline, actions, subscribers, num_user, subscribed, tweet_sent}}
  end
  def handle_cast({:change_user, new_username, new_password}, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}) do
    if :online == state do
      IO.puts("Online now, could not change user")
      {:noreply, {username, password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}}
    else
      {:noreply, {new_username, new_password, tweet_list, state, actions, subscribers, num_user, subscribed, tweet_sent}}
    end
  end

end
