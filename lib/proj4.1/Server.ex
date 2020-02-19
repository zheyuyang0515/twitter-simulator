defmodule Server do
  use GenServer
  def init(:no_arg) do
    {:ok, {%{}, %{}, 0}}
  end
  def start_link() do
    GenServer.start_link(__MODULE__, :no_arg, name: :server)
  end
  def init_db() do
    DataBaseHandler.initiate()
  end
  defp insert_element(table_name, key, value) do
    result = :ets.lookup(table_name, key)
    if length(result) == 0 do
      :ets.insert(table_name, {key, result ++ [value]})
    else
      [{_, data}] = result
      :ets.insert(table_name, {key, data ++ [value]})
    end
  end
  defp checkUserExist(username) do
    password = :ets.lookup(:user_table, username)
    if password == [] do
      {false, nil}
    else
      [{_, {result, is_deleted}}] = password
      if is_deleted == :delete do
        {false, nil}
      else
        {true, result}
      end
    end
  end
  defp check_repete(username) do
    password = :ets.lookup(:user_table, username)
    if password == [] do
      {false, nil}
    else
      [{_, {result, _}}] = password
      {true, result}
    end
  end
  def send_msg(pid, msg) do
    GenServer.call(pid, msg)
  end

  #retweet
  def handle_call({:retweet, tweet_id, comment, username, pid}, _from, {state, user_socket, tweet_sum}) do
    if Map.has_key?(state, username) == false || Map.get(state, username) != pid do
      {:reply, {:invalid_request, nil, nil, nil, nil}, {state, user_socket, tweet_sum}}
    else
      [{_, [{user_id, content, is_new}]}] = :ets.lookup(:tweets_table, tweet_id)
      if is_new == :new_tweet do
        {is_exist, _} = checkUserExist(user_id)
        if is_exist == false do
          {:reply, {:user_not_exist, nil, nil, nil, nil}, {state, user_socket, tweet_sum}}
        else
          tweet_sum = tweet_sum + 1
          insert_element(:tweets_table, tweet_sum, {username, content, :retweet})
          insert_element(:retweet_table, tweet_sum, {tweet_id, user_id, comment})
          #post_tweet
          insert_element(:post_tweets_table, username, tweet_sum)
          #deliver to subscriber who is connected
          subscribers = :ets.lookup(:subscribers_table, username)
          list = if length(subscribers) > 0 do
            [{_, subscribers}] = subscribers
            temp = []
            temp = Enum.map(subscribers, fn subscriber ->
              if Map.has_key?(user_socket, subscriber) do
                pid = Map.get(state, subscriber)
                if(is_pid(pid) == true) do
                  Client.send_msg(pid, {:subscribed_tweet, tweet_sum, username, content, user_id, comment, :retweet})
                  temp
                else
                  temp ++ Map.get(user_socket, subscriber)
                end
                #pid = Map.get(state, subscriber)
              else
                temp
                #Client.send_msg(pid, {:subscribed_tweet, tweet_sum, username, content, user_id, comment, :retweet})
              end
            end)
            temp
          else
            []
          end
          list = List.flatten(list)
          if is_pid(pid) == true do
            Enum.map(list, fn socket ->
              Phoenix.Channel.push(socket, "auto_subscribed_retweet", %{username: username, tweet_id: tweet_id, content: content, source_user: user_id, comments: comment})
            end)
          end
          {:reply, {:success, list, tweet_sum, user_id, content}, {state, user_socket, tweet_sum}}
        end
      else
        tweet_sum = tweet_sum + 1
        [{_, [{source_id, source, _}]}] = :ets.lookup(:retweet_table, tweet_id)
        [{_, [{_, content, _}]}] = :ets.lookup(:tweets_table, source_id)
        insert_element(:tweets_table, tweet_sum, {username, content, :retweet})
        insert_element(:retweet_table, tweet_sum, {source_id, source, comment})
        #post_tweet
        insert_element(:post_tweets_table, username, tweet_sum)
        #deliver to subscriber who is connected
        subscribers = :ets.lookup(:subscribers_table, username)
        list = []
        list = if length(subscribers) > 0 do
          [{_, subscribers}] = subscribers
          Enum.map(subscribers, fn subscriber ->
            if Map.has_key?(user_socket, subscriber) do
              pid = Map.get(state, subscriber)
              if(is_pid(pid) == true) do
                Client.send_msg(pid, {:subscribed_tweet, tweet_sum, username, content, source, comment, :retweet})
                list
              else
                list ++ Map.get(user_socket, subscriber)
              end
              #Client.send_msg(pid, {:subscribed_tweet, tweet_sum, username, content, source, comment, :retweet})
            else
              list
            end
          end)
        else
          []
        end
        list = List.flatten(list)
        if is_pid(pid) == true do
          Enum.map(list, fn socket ->
            Phoenix.Channel.push(socket, "auto_subscribed_retweet", %{username: username, tweet_id: tweet_id, content: content, source_user: source, comments: comment})
          end)
        end
        {:reply, {:success, list, tweet_sum, source, content}, {state, user_socket, tweet_sum}}
      end
    end
  end

  #query tweets which mentioned me
  def handle_call({:query_mentions, username, pid}, _from, {state, user_socket, tweet_sum}) do
    if Map.has_key?(state, username) == false || Map.get(state, username) != pid do
      {:reply, :invalid_request, {state, user_socket, tweet_sum}}
    else
      tweet_ids = :ets.lookup(:mentions_table, username)
      if length(tweet_ids) > 0 do
        [{_, tweet_ids}] = tweet_ids
        result = []
        result = Enum.map(tweet_ids, fn tweet_id ->
          [{_, [{user_id, content, is_new}]}] = :ets.lookup(:tweets_table, tweet_id)
          {is_exist, _} = checkUserExist(user_id)
          if is_exist == false do
            result
          else
            if is_new == :new_tweet do
              result ++ {tweet_id, user_id, content, nil, nil, is_new}
            else
              [{_, [{_, source, comment}]}] = :ets.lookup(:retweet_table, tweet_id)
              result ++ {tweet_id, user_id, content, source, comment, is_new}
            end
          end
        end)
        {:reply, {:success, List.flatten(result)}, {state, user_socket, tweet_sum}}
      else
        {:reply, {:success, []}, {state, user_socket, tweet_sum}}
      end
    end
  end
  #query tweets with a specific hashtag
  def handle_call({:query_hashtag, username, pid, hashtag}, _from,{state, user_socket, tweet_sum}) do
    if Map.has_key?(state, username) == false || Map.get(state, username) != pid do
      {:reply, :invalid_request, {state, user_socket, tweet_sum}}
    else
      tweet_ids = :ets.lookup(:hashtags_table, hashtag)
      if length(tweet_ids) > 0 do
        [{_, tweet_ids}] = tweet_ids
        result = []
        result = Enum.map(tweet_ids, fn tweet_id ->
          [{_, [{user_id, content, is_new}]}] = :ets.lookup(:tweets_table, tweet_id)
          {is_exist, _} = checkUserExist(user_id)
          if is_exist == false do
            result
          else
            if is_new == :new_tweet do
              result ++ {tweet_id, user_id, content, nil, nil, is_new}
            else
              [{_, [{_, source, comment}]}] = :ets.lookup(:retweet_table, tweet_id)
              result ++ {tweet_id, user_id, content, source, comment, is_new}
            end
          end
        end)
        {:reply, {:success, List.flatten(result)}, {state, user_socket, tweet_sum}}
      else
        {:reply, {:success, []}, {state, user_socket, tweet_sum}}
      end
    end
  end
  #query subscribed tweets
  def handle_call({:query_subscribe, username, pid}, _from, {state, user_socket, tweet_sum}) do
    if Map.has_key?(state, username) == false || Map.get(state, username) != pid do
      {:reply, :invalid_request, {state, user_socket, tweet_sum}}
    else
      subscribed = :ets.lookup(:subscribe_to_table, username)
      if length(subscribed) > 0 do
        result = []
        [{_, subscribed}] = subscribed
        result = Enum.map(subscribed, fn sub ->
          {is_exist, _} = checkUserExist(sub)
          if is_exist == false do
            result
          else
            tweet_ids = :ets.lookup(:post_tweets_table, sub)
            if length(tweet_ids) > 0 do
              [{_, tweet_ids}] = tweet_ids
              list = []
              list = Enum.map(tweet_ids, fn tweet_id ->
                [{_, [{user_id, content, is_new}]}] = :ets.lookup(:tweets_table, tweet_id)
                list = if is_new == :new_tweet do
                  list ++ {tweet_id, user_id, content, nil, nil, is_new}
                else
                  [{_, [{_, source, comment}]}] = :ets.lookup(:retweet_table, tweet_id)
                  list ++ {tweet_id, user_id, content, source, comment, is_new}
                end
                list
              end)
              result ++ list
            else
              result
            end
          end
        end)
        {:reply, {:success, List.flatten(result)}, {state, user_socket, tweet_sum}}
      else
        {:reply, {:success, []},{state, user_socket, tweet_sum}}
      end
    end
  end
  #subscribe
  def handle_call({:subscribe, username, pid, target_username}, _from, {state, user_socket, tweet_sum}) do
    if Map.has_key?(state, username) == false || Map.get(state, username) != pid do
      {:reply, {:invalid_request, nil}, {state, user_socket, tweet_sum}}
    else
      if :ets.lookup(:user_table, target_username) == [] do
        {:reply, {:user_not_exist, nil}, {state, user_socket, tweet_sum}}
      else
        insert_element(:subscribers_table, target_username, username)
        insert_element(:subscribe_to_table, username, target_username)
        socket = if(Map.has_key?(user_socket, target_username) == false) do
          nil
        else
          Map.get(user_socket, target_username)
        end
          {:reply, {:success, socket}, {state, user_socket, tweet_sum}}
      end
    end
  end
  #send tweets
  def handle_call({:send_tweet, username, pid, content, hashtags, mentions}, _from, {state, user_socket, tweet_sum}) do
    if Map.has_key?(state, username) == false || Map.get(state, username) != pid do
      {:reply, {:invalid_request, nil, nil, nil}, {state, user_socket, tweet_sum}}
    else
      #tweet_id
      tweet_id = tweet_sum + 1
      insert_element(:tweets_table, tweet_id, {username, content, :new_tweet})
      #post_tweet
      insert_element(:post_tweets_table, username, tweet_id)
      #hashtag
      if length(hashtags) > 0 do
        Enum.map(hashtags, fn hashtag ->
          insert_element(:hashtags_table, hashtag, tweet_id)
        end)
      end
      #mentions
      if length(mentions) > 0 do
        Enum.map(mentions, fn mention ->
          {is_exist, _} = checkUserExist(mention)
          if is_exist == true do
            insert_element(:mentions_table, mention, tweet_id)
          end
        end)
      end
      #deliver to mentioned connected user
      sockets_mentions = []
      sockets_mentions = Enum.map(mentions, fn mention ->
        if Map.has_key?(user_socket, mention) do
          pid = Map.get(state, mention)
          if(is_pid(pid) == true) do
            Client.send_msg(pid, {:mentioned_tweet, tweet_id, username, content, nil, nil, :new_tweet})
            sockets_mentions
          else
            sockets_mentions ++ Map.get(user_socket, mention)
          end
        else
          sockets_mentions
        end
      end)
      #deliver to subscriber who is connected
      sockets_subscribes = []
      subscribers = :ets.lookup(:subscribers_table, username)
      sockets_subscribes = if length(subscribers) > 0 do
        [{_, subscribers}] = subscribers
        list = []
        list = Enum.map(subscribers, fn subscriber ->
          if Map.has_key?(user_socket, subscriber) == true && Enum.member?(sockets_mentions, Map.get(user_socket, subscriber)) == false do
            pid = Map.get(state, subscriber)
            if(is_pid(pid) == true) do
              Client.send_msg(pid, {:subscribed_tweet, tweet_id, username, content, nil, nil, :new_tweet})
              list
            else
              list ++ Map.get(user_socket, subscriber)
            end
            #Client.send_msg(pid, {:subscribed_tweet, tweet_id, username, content, nil, nil, :new_tweet})
          else
            list
          end
        end)
        sockets_subscribes ++ list
      else
        sockets_subscribes
      end
      sockets_subscribes = List.flatten(sockets_subscribes)
      sockets_mentions = List.flatten(sockets_mentions)
      if is_pid(pid) == true do
        Enum.map(sockets_subscribes, fn socket ->
          Phoenix.Channel.push(socket, "auto_subscribed_tweet", %{username: username, tweet_id: tweet_id, content: content, hashtags: hashtags, mentions: mentions})
        end)
        Enum.map(sockets_mentions, fn socket ->
          Phoenix.Channel.push(socket, "auto_mentioned_tweet", %{username: username, tweet_id: tweet_id, content: content, hashtags: hashtags, mentions: mentions})
        end)
      end
      {:reply, {:success, sockets_subscribes, sockets_mentions, tweet_id}, {state, user_socket, tweet_sum + 1}}
    end
  end

  #logout
  def handle_call({:logout, username, pid}, _from, {state, user_socket, tweet_sum}) do
    if Map.has_key?(state, username) == false do
      {:reply, :user_offline, {state, user_socket, tweet_sum}}
    else
      if Map.get(state, username) != pid do
        {:reply, :invalid_request, {state, user_socket, tweet_sum}}
      else
        state = Map.delete(state, username)
        user_socket = Map.delete(user_socket, username)
        {:reply, :success, {state, user_socket, tweet_sum}}
      end
    end
  end

  #login
  def handle_call({:login, username, password, pid, socket}, _from, {state, user_socket, tweet_sum}) do
    {is_exist, auth_password} = checkUserExist(username)
    if is_exist == false do
      #IO.puts("Sorry! This username is not exist, please try again.")
      {:reply, :username_not_exist, {state, user_socket, tweet_sum}}
    else
      password = Helper.sha_hash(password)
      if password != auth_password do
        #IO.puts("Sorry! The password is incorrect, please try again.")
        {:reply, :password_incorrect, {state, user_socket, tweet_sum}}
      else
        if Map.has_key?(state, username) == true && Map.get(state, username) != pid do
          #IO.puts("Sorry! This user is alreay online.")
          {:reply, :login_repeat, {state, user_socket, tweet_sum}}
        else
          #IO.puts("Login Success! Welcome back: " <> username <> "!")
          state = if Map.has_key?(state, username) == false do
            Map.put(state, username, pid)
          else
            state
          end
          {:reply, :success, {state, Map.put(user_socket, username, socket), tweet_sum}}
        end
      end
    end
  end

  #delete account
  def handle_call({:delete_account, username, password}, _from, {state, user_socket, tweet_sum}) do
    {is_repeated, auth_password} = checkUserExist(username)
    if is_repeated == false do
      {:reply, :username_not_exist, {state, user_socket, tweet_sum}}
    else
      password = Helper.sha_hash(password)
      if password == auth_password do
        :ets.delete(:user_table, username)
        :ets.insert(:user_table, {username, {password, :delete}})
        #IO.puts("The account " <> username <> " has been deleted. The tweets sent by this account are invisible to other users.")
        state = if Enum.member?(state, username) do
          Map.delete(state, username)
        else
          state
        end
        user_socket = if Enum.member?(user_socket, username) do
          Map.delete(user_socket, username)
        else
          user_socket
        end
        {:reply, :success, {state, user_socket, tweet_sum}}
      else
        {:reply, :password_incorrect, {state, user_socket, tweet_sum}}
      end
    end
  end

  #register account
  def handle_call({:registration, username, password}, _from, {state, user_socket, tweet_sum}) do
    {is_repeated, _} = check_repete(username)
    if is_repeated == true do
      {:reply, :failed, {state, user_socket, tweet_sum}}
    else
      password = Helper.sha_hash(password)
      :ets.insert(:user_table, {username, {password, :active}})
      {:reply, :success, {state, user_socket, tweet_sum}}
    end
  end
end
