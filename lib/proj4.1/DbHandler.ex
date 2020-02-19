defmodule DataBaseHandler do
  def initiate do
    :ets.new(:user_table, [:set, :public, :named_table]);
    :ets.new(:tweets_table, [:set, :public, :named_table]);
    :ets.new(:post_tweets_table, [:set, :public, :named_table]);
    :ets.new(:hashtags_table, [:set, :public, :named_table]);
    :ets.new(:mentions_table, [:set, :public, :named_table]);
    :ets.new(:subscribers_table, [:set, :public, :named_table]);
    :ets.new(:subscribe_to_table, [:set, :public, :named_table]);
    :ets.new(:retweet_table, [:set, :public, :named_table]);
  end
end



#user table, store user's information : user_id(int), password(varchar), username(varchar) 
#tweets table, store tweets information: tweet_id(int), username(varchar), content(varchar), original(boolean/tinyint)
#mentioned table, store map of tweets and its mentioned users: id(int), tweet_id(int), mentioned(varchar)
#hashtags table, store map of tweets and their hashtags: id(int), tweet_id(int), hashtag(varchar)
#subscribers table, store the map of users and his subscribers: id(int), username(varchar), subscribers(varchar)
#retweet table, store retweet information: id(int), username(varchar), tweet_id(int), source_id(int), comment(varchar)

