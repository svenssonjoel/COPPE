import json


#Todo check that cmd is well formed

replySuccess = '{"status" : "ok"}'
replyFailure = '{"status" : "failed"}'


def process(cmd):

    if "command" in cmd:
        print(cmd["command"])
        return replySuccess
    else:
        print("error no command")
        return replyFailure
        
        
