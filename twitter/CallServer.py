import urllib.request
import urllib.parse

def serverCall(tweetText):
	urllib.request.urlopen("http://server.calstephens.tech:8081/uploadQuery?tweet-text=" + urllib.parse.quote(tweetText)).read()
	#True for false
	#some print