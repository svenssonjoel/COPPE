import json
from flask import Flask, request, jsonify

# from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

@app.route('/', methods = ['GET'])
def hello():
    return 'Hello, World! Again!'


@app.route('/', methods = ['POST'])
def post():
    data = json.loads(request.data)
    return jsonify(data)


app.run(debug = True)

