﻿﻿﻿﻿﻿﻿# COP5615 - Dist Oper Sys Princ - Fall 2019 - Project4.2
---
## Step to run the code
---
```
 cd proj4
 mix phx.server
```
After start the server, open a browser and enter URL 'localhost:4000' to access to our front-end webpage.
## Functionalities
---
1. Registration: Users could register with their usernames(unique) and passwords(repeat allowed), the server would store the username and password. Moreover, the password was encrypted using SHA-1. 
2. Account Deletion: Users could delete accounts with usernames and correspond passwords. If an account is deleted, the tweets it sent is also invisible to other users.
3. Login: Users could login with their usernames and correspond passwords. 
4. Logout: Users could logout with their username.
5. Tweets Sending: Users could send a tweet with their usernames. A tweet is consists of 3 parts: content, a list of hashtags and a list of mentioned users.
6. Retweet: Users could forward others tweets, a forwarded tweet is consists of 3 parts: content, comments, original user.
7. Subscribed: A user could subscribe other users.
8. Query With a Specific Hashtag: Users could search tweets which include a specific hashtag.
9. Query Mentioned Tweets: A user could search tweets which mentioned him.
10. Query Subscribed: A user could search tweets which he subscribed.
11. Tweets Automatic Delivery: If a user is connected, he could receive subscribed tweets or tweets which mentioned him live.
12. 100 users simulation: When the server started, 100 users will be created by the simulator, these simulated user will do action randomly and based on the Zipf distribution. User who access to our front-end could subscribe these 100 simulated users and search and receive their tweets.

 














