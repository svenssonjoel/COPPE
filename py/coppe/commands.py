import json


#Todo check that cmd is well formed

replySuccess = '{"command-status" : "ok"}'
replyFailure = '{"command-status" : "failed"}'


def process(cmd):

    if "command" in cmd:
        print(cmd["command"])
        return replySuccess
    else:
        print("error no command")
        return replyFailure
        
        
