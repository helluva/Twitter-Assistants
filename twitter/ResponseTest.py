import tweepy, datetime, json, time

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

		#for 20 seconds or so pull for Alexa/assistant responses
		#threading.Timer(2.0, CallServer.responseCall(taskID)).start()
		endTime = time.time() + 200
		shouldContinuePolling = True

		hasSentAlexaReply = False
		hasSentGoogleReply = False
		hasSentSiriReply = False

		while time.time() < endTime or shouldContinuePolling:
			assistantResponses = CallServer.responseCall(taskID)
			datastore2 = json.loads(assistantResponses)

			siriResponse = None
			alexaResponse = None
			googleResponse = None

			print(datastore2)

			if datastore2["siri-response"] != 'WAITING_FOR_RESPONSE':
				siriResponse = datastore2["siri-response"]

			if datastore2["alexa-response"] != 'WAITING_FOR_RESPONSE':
				alexaResponse = datastore2["alexa-response"]

			if datastore2["google-response"] != 'WAITING_FOR_RESPONSE':
				googleResponse = datastore2["google-response"]

			if siriResponse == None or alexaResponse == None or googleResponse == None:
				print("still waiting...")
				print("SIRI: " + datastore2["siri-response"])
				print("ALEXA: " + datastore2["alexa-response"])
				print("GOOGLE:" + datastore2["google-response"])
				print(time.time())

			print(datastore2)
			mostRecentTweetId = ""

			#tweet the siri response if it exists 
			if (siriResponse is not None and siriResponse != "WAITING_FOR_RESPONSE" and not hasSentSiriReply):
			  tweeterName = tweet.user.screen_name
			  siriMessage = "@" + str(tweeterName) + " " + siriResponse
			  print("Tweeted " + siriMessage)

			  #this sends our tweet
			  auth = tweepy.OAuthHandler(keys['siri_consumer_key'], keys['siri_consumer_secret'])
			  auth.set_access_token(keys['siri_access_token'], keys['siri_access_token_secret'])
			  api = tweepy.API(auth)
			  tweet = api.update_status(siriMessage, tweet.id)
			  print ("Replied to ID: " + str(tweet.id))
			  mostRecentTweetId = tweet.id
			  hasSentSiriReply = True

			#tweet the alexa response if it exists 
			if (alexaResponse is not None and alexaResponse != "WAITING_FOR_RESPONSE" and not hasSentAlexaReply):
			  tweeterName = tweet.user.screen_name
			  alexaMessage = "@" + str(tweeterName) + " " + alexaResponse
			  print("Tweeted " + alexaMessage)

			  #this sends our tweet
			  auth = tweepy.OAuthHandler(keys['alexa_consumer_key'], keys['alexa_consumer_secret'])
			  auth.set_access_token(keys['alexa_access_token'], keys['alexa_access_token_secret'])
			  api = tweepy.API(auth)
			  tweet = api.update_status(alexaMessage, tweet.id)
			  print ("Replied to ID: " + str(tweet.id))
			  mostRecentTweetId = tweet.id
			  hasSentAlexaReply = True

			#tweet the alexa response if it exists 
			if (googleResponse is not None and googleResponse != "WAITING_FOR_RESPONSE" and not hasSentGoogleReply):
			  tweeterName = tweet.user.screen_name
			  googleMessage = "@" + str(tweeterName) + " " + googleResponse
			  print("Tweeted " + googleMessage)

			  #this sends our tweet
			  auth = tweepy.OAuthHandler(keys['google_consumer_key'], keys['google_consumer_secret'])
			  auth.set_access_token(keys['google_access_token'], keys['google_access_token_secret'])
			  api = tweepy.API(auth)
			  tweet = api.update_status(googleMessage, tweet.id)
			  print ("Replied to ID: " + str(tweet.id))
			  mostRecentTweetId = tweet.id
			  hasSentGoogleReply = True

			if mostRecentTweetId is not "":
			  #write most recent reply tweet.id to file
			  idFile = open("last_id_replied.py","w")
			  idFile.write(str(tweet.id))
			  idFile.close()

			if hasSentGoogleReply and hasSentAlexaReply and hasSentSiriReply:
				  shouldContinuePolling = False

			time.sleep(3)



