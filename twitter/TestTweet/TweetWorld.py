import tweepy, time, sys
 
argfile = str(sys.argv[1])
 
CONSUMER_KEY = '7CchEpt4QJm8LidOMA75kFQfs'
CONSUMER_SECRET = 'ZaEym1Gq5iYtno7AbGj107xRTXYMqXWcRKXvFq26XjcBTGcpw7'
ACCESS_KEY = '957463213322489857-qjl7A17F4m8qIVUm9A5oKgKRiS3wF3Q'
ACCESS_SECRET = 'HAfnpOmzrLlCqGEPC7XJU5TCYeidiyNebZT7aNMBHu2we'
auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_KEY, ACCESS_SECRET)
api = tweepy.API(auth)
 
filename=open(argfile,'r')
f=filename.readlines()
filename.close()
 
for line in f:
    api.update_status(line)
    time.sleep(900)#Tweet every 15 mins = 900