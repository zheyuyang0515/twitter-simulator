defmodule Helper do
  def sha_hash(ctx) do
    sha = :crypto.hash_init(:sha)
    sha = :crypto.hash_update(sha, ctx)
    sha_binary = :crypto.hash_final(sha)
    sha_hex = sha_binary |> Base.encode16
    sha_hex
  end

  def create_tweet(username, num_user) do
    random = Enum.random(0..div(num_user, 2)) |> to_string
    random2 = Enum.random(div(num_user, 2) + 1..num_user - 1) |> to_string
    list = [{"#COP5615 is perfectly great.", ["#COP5615"], []}, {"Today is a great day!", [], []}, {username <> " just got an A in #COP5615 #FINAL EXAM!!", ["COP5615", "#FINAL EXAM"], []}, {"@"<> random <> ", I don't want to quarrel with you. I am so upset today. I do apologize to you.", [], [random]}, {"#UF is a wonderful university to live and study!!! @"<>random<>", @"<>random2, ["#UF"], [random, random2]},
            {"The projects in #COP5615 taught me a lot", ["#COP5615"], []}, {"I just received an offer from #UF @" <> random2, ["#UF"], [random2]}, {"@"<>random<>" Does #COP5615 in #UF worth to take?", ["#COP5615", "#UF"], [random]}]
    Enum.random(list)
  end
end
