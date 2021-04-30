import sys
import json

from coppe import commands

from flask import Flask, request, jsonify

if len(sys.argv) < 2:
    print('More arguments please!')
    

app = Flask(__name__)

@app.route('/', methods = ['GET'])
def hello():
    return 'CoppeServ is running!'

@app.route('/', methods = ['POST'])
def post():
    data = json.loads(request.data)
    reply = commands.process(data)
    return jsonify(reply)


app.run(debug = True)


