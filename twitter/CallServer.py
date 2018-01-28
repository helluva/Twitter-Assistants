import urllib.request
import urllib.parse

def serverCall(tweetText):
	response = urllib.request.urlopen("http://server.calstephens.tech:8081/uploadQuery?tweet-text=" + urllib.parse.quote(tweetText)).read()
	#True for false
	#some print

	return response

def responseCall(taskID):
	assistantResponses = urllib.request.urlopen("http://server.calstephens.tech:8081/deliverAssistantResponses?task-id=" + urllib.parse.quote(taskID)).read()
	#True for false
	#some print

	return response