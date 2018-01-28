const express = require('express')
const path = require('path')
const request = require('request')
const bodyParser = require('body-parser')
const fs = require('fs')
const uuid = require('uuid/v4')

const app = express()

app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json({limit: "100mb"}))
app.use(bodyParser.raw({limit: "100mb"}))

//setup endpoints

var queued_tasks = []
var completed_tasks = []
var rawtexts = {}
var waiting_for_server = false


//***********************
//client-facing endpoints
//***********************

//uploads a tweet query through query["tweet-text"]. response["task-id"] is an identifier for the queued task.
app.get('/uploadQuery', (request, response) => {
    let task_id = uuid()
    
    //use the raw text if it exists -- otherwise check for the recording
    rawtexts[task_id] = request.query["tweet-text"]
    console.log("received \"" + request.query["tweet-text"] + "\"")
    
    queued_tasks.push(task_id)
    console.log(queued_tasks)
    response.send({'status': 'success', 'task-id': task_id})
})

//body["task-id"] should be an identifier from /uploadBlob.
//response["code"] is either unknown-task, waiting-for-server, or response-ready.
//if response-ready, then response["response"] will be something when i get to it
app.post('/pollForSiriResponse', (request, response) => {
    var taskId = request.body["task-id"]
    
    if (!completed_tasks.includes(taskId)) {
        if (!queued_tasks.includes(taskId)) {
            response.send({'status': 'failure', 'code': 'unknown-task'})
        } else {
            response.send({'status': 'failure', 'code': 'waiting-for-server'})
        }
        return
    }
    
    response.send({'status': 'success', 'code': 'response-ready'})
})


//server-facing endpoints


app.get('/reset', (request, response) => {
    waiting_for_server = false
    response.send({status: 'success'})
})

app.get('/tweetsAvailable', (request, response) => {
    console.log("tweets avaiable? "+ queued_tasks)
    
    if (waiting_for_server) {
        response.send("false")
        return
    }
    
    if (queued_tasks.length == 0) {
        response.send("false")
    } else {
        response.send(queued_tasks[0]) //send the first task id
        waiting_for_server = true //don't send another tweet until the server sends back a response
    }
})

//if the next query has a rawtext, return that rawtext. Otherwise, "false".
app.get('/nextTweet', (request, response) => {
    if (queued_tasks.length == 0) {
        response.send("false")
    } else {
        task_id = queued_tasks[0]
        nextTweet = rawtexts[task_id]
        response.send(nextTweet)
    }
})

//request.body is {"task-id": ..., "siri-response": ..., "alexa-response": ...}
app.post('/deliverAssistantResponses', (request, response) => {
    
    task_id = request.body["task-id"]
    siri_response = request.body["siri-response"]
    alexa_response = request.body["alexa-response"]
    
    if (task_id == undefined 
        || siri_response == undefined 
        || alexa_response == undefined ) 
    {
        response.send({status: 'failure'})
        return
    }
    
    queued_tasks.shift() //remove the current task
    //array.splice(queued_tasks, queued_tasks.indexOf(task_id)) //remove the task
    waiting_for_server = false //allow the server to receive more recordings
    
    completed_tasks.push(task_id)
    response.send({status: 'success'})
})


//publicize server

function makeDirectoryPublic(name) {
    app.use(express.static(__dirname + name));
    app.use(name, express.static(__dirname + name));
}

['/assets', '/scripts', '/css', '/siri-responses', '/recordings'].forEach(makeDirectoryPublic)

app.listen(8081)