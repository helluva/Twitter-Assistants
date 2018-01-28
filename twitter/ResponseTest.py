import tweepy, datetime, json, threading

from twitter_keys import keys

import CallServer

def run_reply_cycle():
	currentTime = datetime.datetime.now()

	#this file stores only the id of the last tweeter that was replied to
	idFile = open("last_id_replied.py","r")
	last_id_replied = idFile.read()
	idFile.close()

	#tweepy setting and handling keys
	CONSUMER_KEY = keys['consumer_key']
	CONSUMER_SECRET = keys['consumer_secret']
	ACCESS_TOKEN = keys['access_token']
	ACCESS_TOKEN_SECRET = keys['access_token_secret']
	 
	auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
	auth.set_access_token(ACCESS_TOKEN, ACCESS_TOKEN_SECRET)
	api = tweepy.API(auth)

	#old way to search for mentions
	#tweets = api.search(q="@Alexa_vs_Siri")

	#consists of all tweets since last id that has been replied, can only do this for up to 20 tweets at a time
	print("lastID of last cylce: " + last_id_replied)
	mentionTweets = api.mentions_timeline(since_id = last_id_replied)

	#for all tweets @'ed to the bot...
	#if tweet.lang == "en" restricts responses to english only tweets
	for tweet in mentionTweets:
	  
	  #also strips out @Alexa_vs_Siri handle at beginning
	  print("Mention said: " + tweet.text[15:])
	  #sends Mention to Alexa and gets jsonResponse
	  jsonResponseString = CallServer.serverCall(tweet.text[15:])


	  #Server call to get response message goes here
	  datastore = json.loads(jsonResponseString)
	  taskID = datastore["task-id"]
	  print(taskID)
	  
	  #Every 2 seconds or so pull for Alexa/assistant responses
	  threading.Timer(2.0, CallServer.responseCall(taskID)).start()
	  datastore2 = json.loads(assistantResponses)
	  print(datastore2)

	  tweeterName = tweet.user.screen_name
	  #@'ing the tweeterName a response message
	  message = "@" + str(tweeterName) + " " + str(currentTime.hour) + ":" + str(currentTime.minute) + ":" + str(currentTime.second) + " " + "Hey nort, I'm a bot"


	  #this sends our tweet
	  tweet = api.update_status(message, tweet.id)
	  print ("Replied to ID: " + str(tweet.id))

	  #write most recent reply tweet.id to file
	  idFile = open("last_id_replied.py","w")
	  idFile.write(str(tweet.id))
	  idFile.close()