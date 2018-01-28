import tweepy, datetime

from twitter_keys import keys

currentTime = datetime.datetime.now()

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
print("lastID: " + last_id_replied)
mentionTweets = api.mentions_timeline(since_id = last_id_replied)

#for all tweets @'ed to the bot...
#if tweet.lang == "en" restricts responses to english only tweets
for tweet in mentionTweets:
  tweeterName = tweet.user.screen_name
  #@'ing the tweeterName
  message = "@" + str(tweeterName) + " " + str(currentTime.hour) + ":" + str(currentTime.minute) + ":" + str(currentTime.second) + " " + "Hey nort, I'm a bot"
  

  #this sends our tweet
  tweet = api.update_status(message, tweet.id)
  print (str(tweet.id))
  idFile = open("last_id_replied.py","w")
  idFile.write(str(tweet.id))
  idFile.close()