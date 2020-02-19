// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()
// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("room:lobby", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })
let register_btn = document.querySelector("#registration");
let register_username_input = document.querySelector("#register_username");
let register_password_input = document.querySelector("#register_password");
if(register_btn) {
  register_btn.addEventListener("click", function(){  
    if(register_username_input.value == "") {
      alert("Username could not be empty.")
    } else if(register_password_input.value == "") {
      alert("Password could not be empty.")
    } else {
      channel.push("registration", {username: register_username_input.value, password: register_password_input.value})
      .receive("register_success" , _ => { alert("Register Successfully!"); window.location.replace("/")})
      .receive("register_failed" , _ => { alert("Register Failed: Username is exist. Please change another one!")}) 
      register_username_input.value = "";
      register_password_input.value = "";
    }
  })
}
let login_username_input = document.querySelector("#username");
let login_password_input = document.querySelector("#password");
let login_btn = document.querySelector("#login");
let valid_password
let valid_username
if(login_btn) {
  login_btn.addEventListener("click", function(){  
    channel.push("login", {username: login_username_input.value, password: login_password_input.value})
      .receive("username_not_exist" , _ => { alert("Username not exist."); login_username_input.value = "";
      login_password_input.value = ""})
      .receive("password_incorrect" , _ => { alert("Password incorrect"); login_password_input.value = ""}) 
      .receive("login_repeat" , _ => {alert("This user has loged in on another device.");}) 
      .receive("success" , resp => {login_username_input.value = ""; login_password_input.value = ""; valid_username = resp["username"]; valid_password = resp["password"]; document.getElementById("login_page").style.display="none"; document.getElementById("main_page").style.display=""; document.getElementById("main_page_username").innerHTML=resp["username"];}) 
    })
}
let logout_btn = document.querySelector("#logout");
if(logout_btn) { 
    logout_btn.addEventListener("click", function(){ 
      var confirmation = confirm("Logout: " + valid_username + "?");
      if (confirmation == true){
        channel.push("logout", {username: valid_username})
        .receive("success" , _ => {document.getElementById("messages").innerHTML=""; valid_username = ""; document.getElementById("main_page").style.display="none"; document.getElementById("login_page").style.display="";})
        .receive("user_offline" , _ => {valid_username = ""; document.getElementById("main_page").style.display="none"; document.getElementById("login_page").style.display="";}) 
        .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
      }  
    })
}
let delete_account_btn = document.querySelector("#delete_account");
if(delete_account_btn) { 
  delete_account_btn.addEventListener("click", function(){ 
    var confirmation = confirm("Confirmation: If you delete the account: " + valid_username + ", the tweets you sent will be invisible to other users.");
    if (confirmation == true){
      channel.push("delete_account", {username: valid_username, password: valid_password})
      .receive("success" , _ => {valid_username = ""; document.getElementById("main_page").style.display="none"; document.getElementById("login_page").style.display="";})
      .receive("username_not_exist" , _ => {alert("Invalid Request: Username Not Exist!")}) 
      .receive("password_incorrect" , _ => {alert("Invalid Request: Password Incorrect.")}) 
    }  
  })
}
let mentions = document.querySelector("#mentioned");
let hashtags = document.querySelector("#hashtags");
let tweet_content = document.querySelector("#tweet_content");
let send_tweet_btn = document.querySelector("#send_tweet");
if(send_tweet_btn) { 
  send_tweet_btn.addEventListener("click", function(){ 
    channel.push("send_tweet", {username: valid_username, content: tweet_content.value, hashtags: hashtags.value, mentions: mentions.value})
    .receive("success" , _ => {
      let messageItem = document.createElement("button");
      messageItem.className = "retweet_btn"
      if(mentions.value != "" && hashtags.value != "") {
        messageItem.innerText = "[" + Date() +"] " + valid_username + ": " + tweet_content.value + "(mentioned: " + mentions.value + "; HashTags: " + hashtags.value + ").";
      } else if(mentions.value != "") {
        messageItem.innerText = "[" + Date() +"] " + valid_username + ": " + tweet_content.value + "(mentioned: " + mentions.value + ").";
      } else if(hashtags.value != "") {
        messageItem.innerText = "[" + Date() +"] " + valid_username + ": " + tweet_content.value + "(HashTags: " + hashtags.value + ").";
      } else {
        messageItem.innerText = "[" + Date() +"] " + valid_username + ": " + tweet_content.value;
      }
      messagesContainer.appendChild(messageItem)
      mentions.value = ""
      hashtags.value = ""
      tweet_content.value = ""
      send_tweet_btn.disabled = true; 
    })
  })
}
let messagesContainer = document.querySelector("#messages")
let target_username = document.querySelector("#subscribe_input");
let subscribe_btn = document.querySelector("#subscribe");
if(subscribe_btn) { 
  subscribe_btn.addEventListener("click", function(){ 
    channel.push("subscribe", {username: valid_username, target_username: target_username.value})
    .receive("success" , _ => {
      let messageItem = document.createElement("button");
      messageItem.className = "retweet_btn"
      messageItem.innerText = "[" + Date() +"] " + "Subscribe " + target_username.value + " successfully!";
      messagesContainer.appendChild(messageItem)
      target_username.value = ""
      subscribe_btn.disabled = true; 
    })
    .receive("user_not_exist" , _ => {alert("User " + target_username.value + " Not Exist!");target_username.value = ""
    subscribe_btn.disabled = true; }) 
    .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
  })
}
let search_hashtag_btn = document.querySelector("#search_hashtag");
let search_hashtag_input = document.querySelector("#search_hashtag_input");
if(search_hashtag_btn) {
  search_hashtag_btn.addEventListener("click", function(){
    channel.push("query_hashtag", {username: valid_username, hashtag: search_hashtag_input.value})
    .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")})
    .receive("success" , results => {
      search_hashtag_input.value = ""
      search_hashtag_btn.disabled = "true"
      if(results.result.length == 0) {
        alert("No Result.")
      } else {
        for(var i = 0; i < results.result.length; i++) {
          let messageItem = document.createElement("button");
          messageItem.className = "retweet_btn"
          messageItem.id = results.result[i].tweet_id
          if(results.result[i].source_username == null) {
            messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + ": " + results.result[i].content
          } else {
            if(results.result[i].comment == null) {
              messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + "(Retweet From " + results.result[i].source_username +"): "+ results.result[i].content;
            } else {
              messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + "(Retweet From " + results.result[i].source_username +"): "+ results.result[i].content + " | Comments: " + results.result[i].comment;
            }
          }
          messagesContainer.appendChild(messageItem)
          messageItem.addEventListener("click", function() {
            var comments = prompt("Please write your comments:","");
            if(comments != null) {
              channel.push("retweet", {username: valid_username, tweet_id: parseInt(messageItem.id), comments: comments})
              .receive("user_not_exist" , _ => {alert("User Not Exist!")})
              .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
              .receive("success", resp =>  {let messageItem = document.createElement("button");
              messageItem.className = "retweet_btn"
              if(comments == "") {
                messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ resp["content"];
              } else {
                messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ resp["content"] + " | Comments: " + resp["comments"];
              }
              messagesContainer.appendChild(messageItem)})
            }
          })
        }
      }
    })
  })
}
let search_subscribed_btn = document.querySelector("#search_subscribed");
if(search_subscribed_btn) {
  search_subscribed_btn.addEventListener("click", function(){
    channel.push("query_subscribed", {username: valid_username})
    .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")})
    .receive("success" , results => {
      if(results.result.length == 0) {
        alert("No Result.")
      } else {
        for(var i = 0; i < results.result.length; i++) {
          let messageItem = document.createElement("button");
          messageItem.className = "retweet_btn"
          messageItem.id = results.result[i].tweet_id
          if(results.result[i].source_username == null) {
            messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + ": " + results.result[i].content
          } else {
            if(results.result[i].comment == null) {
              messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + "(Retweet From " + results.result[i].source_username +"): "+ results.result[i].content;
            } else {
              messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + "(Retweet From " + results.result[i].source_username +"): "+ results.result[i].content + " | Comments: " + results.result[i].comment;
            }
          }
          messagesContainer.appendChild(messageItem)
          messageItem.addEventListener("click", function() {
            var comments = prompt("Please write your comments:","");
            if(comments != null) {
              channel.push("retweet", {username: valid_username, tweet_id: parseInt(messageItem.id), comments: comments})
              .receive("user_not_exist" , _ => {alert("User Not Exist!")})
              .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
              .receive("success", resp =>  {let messageItem = document.createElement("button");
              messageItem.className = "retweet_btn"
              if(comments == "") {
                messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ resp["content"];
              } else {
                messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ resp["content"] + " | Comments: " + resp["comments"];
              }
              messagesContainer.appendChild(messageItem)})
            }
          })
        }
      }
    })
  })
}


let search_mentioned_btn = document.querySelector("#search_mentioned");
if(search_mentioned_btn) {
  search_mentioned_btn.addEventListener("click", function(){
    channel.push("query_mentioned", {username: valid_username})
    .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")})
    .receive("success" , results => {
      if(results.result.length == 0) {
        alert("No Result.")
      } else {
        for(var i = 0; i < results.result.length; i++) {
          let messageItem = document.createElement("button");
          messageItem.className = "retweet_btn"
          messageItem.id = results.result[i].tweet_id
          if(results.result[i].source_username == null) {
            messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + ": " + results.result[i].content
          } else {
            if(results.result[i].comment == null) {
              messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + "(Retweet From " + results.result[i].source_username +"): "+ results.result[i].content;
            } else {
              messageItem.innerText = "[" + Date() +"] " + results.result[i].sender_username + "(Retweet From " + results.result[i].source_username +"): "+ results.result[i].content + " | Comments: " + results.result[i].comment;
            }
          }
          messagesContainer.appendChild(messageItem)
          messageItem.addEventListener("click", function() {
            var comments = prompt("Please write your comments:","");
            if(comments != null) {
              channel.push("retweet", {username: valid_username, tweet_id: parseInt(messageItem.id), comments: comments})
              .receive("user_not_exist" , _ => {alert("User Not Exist!")})
              .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
              .receive("success", resp =>  {let messageItem = document.createElement("button");
              messageItem.className = "retweet_btn"
              if(comments == "") {
                messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ resp["content"];
              } else {
                messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ resp["content"] + " | Comments: " + resp["comments"];
              }
              messagesContainer.appendChild(messageItem)})
            }
          })
        }
      }
    })
  })
}

channel.on("new_subscriber", payload => {
  let messageItem = document.createElement("button");
  messageItem.className = "retweet_btn"
  messageItem.innerText = "[" + Date() +"] " + "New Subscriber: " + payload.username + ".";
  messagesContainer.appendChild(messageItem)
})
channel.on("auto_subscribed_tweet", payload => {
  let messageItem = document.createElement("button");
  messageItem.className = "retweet_btn" 
  if(payload.hashtags != "" && payload.mentions != "") {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content + "(mentioned: " + payload.mentions + "; HashTags: " + payload.hashtags + ").";
  } else if(payload.mentions != "") {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content + "(mentioned: " + payload.mentions + ").";
  } else if(payload.hashtags != "") {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content + "(HashTags: " + payload.hashtags + ").";
  } else {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content;
  }
  messagesContainer.appendChild(messageItem)
  messageItem.addEventListener("click", function() {
    var comments = prompt("Please write your comments:","");
    if(comments != null) {
      channel.push("retweet", {username: valid_username, tweet_id: payload.tweet_id, comments: comments})
      .receive("user_not_exist" , _ => {alert("User Not Exist!")})
      .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
      .receive("success", resp =>  {let messageItem = document.createElement("button");
      messageItem.className = "retweet_btn"
      if(comments == "") {
        messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ payload.content;
      } else {
        messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ payload.content + " | Comments: " + comments;
      }
      messagesContainer.appendChild(messageItem)})
    }
  })
})
channel.on("auto_subscribed_retweet", payload => {
  let messageItem = document.createElement("button");
  messageItem.className = "retweet_btn"
  if(payload.comments == "") {
    messageItem.innerText = "[" + Date() +"] " + payload.username + "(Retweet From " + payload.source_user +"): "+ payload.content;
  } else {
    messageItem.innerText = "[" + Date() +"] " + payload.username + "(Retweet From " + payload.source_user +"): "+ payload.content + " | Comments: " + payload.comments;
  } 
  messagesContainer.appendChild(messageItem)
  messageItem.addEventListener("click", function() {
    var comments = prompt("Please write your comments:","");
    if(comments != null) {
      channel.push("retweet", {username: valid_username, tweet_id: payload.tweet_id, comments: comments})
      .receive("user_not_exist" , _ => {alert("User Not Exist!");})
      .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
      .receive("success", resp =>  {let messageItem = document.createElement("button");
      messageItem.className = "retweet_btn"
      if(comments == "") {
        messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ payload.content;
      } else {
        messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ payload.content + " | Comments: " + comments;
      }
      messagesContainer.appendChild(messageItem)})
    }
    
  })
})

channel.on("auto_mentioned_tweet", payload => {
  let messageItem = document.createElement("button");
  messageItem.className = "retweet_btn"
  if(payload.hashtags != "" && payload.mentions != "") {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content + "(mentioned: " + payload.mentions + "; HashTags: " + payload.hashtags + ").";
  } else if(payload.mentions != "") {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content + "(mentioned: " + payload.mentions + ").";
  } else if(payload.hashtags != "") {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content + "(HashTags: " + payload.hashtags + ").";
  } else {
    messageItem.innerText = "[" + Date() +"] " + payload.username + ": " + payload.content;
  }
  messagesContainer.appendChild(messageItem)
  messageItem.addEventListener("click", function() {
    var comments = prompt("Please write your comments:","");
    if(comments != null) {
      channel.push("retweet", {username: valid_username, tweet_id: payload.tweet_id, comments: comments})
      .receive("user_not_exist" , _ => {alert("User Not Exist!")})
      .receive("invalid_request" , _ => {alert("Invalid Request: Unauthorized Request.")}) 
      .receive("success", resp =>  {let messageItem = document.createElement("button");
      messageItem.className = "retweet_btn"
      if(comments == "") {
        messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ payload.content;
      } else {
        messageItem.innerText = "[" + Date() +"] " + valid_username + "(Retweet From " + resp["source_user"] +"): "+ payload.content + " | Comments: " + comments;
      }
      messagesContainer.appendChild(messageItem)})
    }    
  })
})

export default socket
