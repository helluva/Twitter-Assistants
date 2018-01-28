import tweepy, datetime

from twitter_keys import keys

currentTime = datetime.datetime.now()

#tweepy setting and handling keys
CONSUMER_KEY = keys['consumer_key']
CONSUMER_SECRET = keys['consumer_secret']
ACCESS_TOKEN = keys['access_token']
ACCESS_TOKEN_SECRET = keys['access_token_secret']
 
auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_TOKEN, ACCESS_TOKEN_SECRET)
api = tweepy.API(auth)

tweets = api.search(q="@Alexa_vs_Siri")

#for all tweets @'ed to the bot...
for tweet in tweets:
  tweeterName = tweet.user.screen_name
  #@'ing the tweeterName
  message = "@" + str(tweeterName) + " " + str(currentTime.hour) + ":"
  + str(currentTime.minute) + ":" + str(currentTime.second)
  + " " + "Hey nort, I'm a bot"
  #this sends our tweet
  tweet = api.update_status(message, tweet.id)