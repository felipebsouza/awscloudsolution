import os

import boto3

from flask import Flask
from flask import jsonify, request

app = Flask(__name__)

# USERS_TABLE = os.environ['cpfevents']
tablename = 'BaseC'
client = boto3.client('dynamodb')


@app.route('/')
def index():
    return 'Index Page'

@app.route('/hello')
def hello():
    return 'Hello, World'

@app.route("/test/<string:cpfnumber>")
def getcpf(cpfnumber):
    return 'cpf: {}'.format(cpfnumber)

@app.route("/getLastEvent/<string:cpfnumber>")
def get_LastEvent(cpfnumber):
    resp = client.get_item(
        TableName=tablename,
        Key={
            'cpf': { 'S': cpfnumber }
        }
    )
    item = resp.get('Item')
    if not item:
        return jsonify({'error': 'Event does not exist'}), 404

    return jsonify({
        'event': item.get('event').get('S'),
        'value': item.get('value').get('S')
    })

@app.route("/getEvent/<string:cpfnumber>/<string:event>")
def get_specificEvents(cpfnumber,event):
    resp = client.get_item(
        TableName=tablename,
        Key={
            'cpf': { 'S': cpfnumber },
            'event': {'S': event }
        }
    )
    
    item = resp.get('Item')
    
    if not item:
        return jsonify({'error': 'Event does not exist'}), 404

    return jsonify({
        'event': item.get('event').get('S'),
        'value': item.get('value').get('S') }
    )

@app.route("/addEvent", methods=["POST"])
def create_event():
    cpf = request.json.get('cpf')
    event = request.json.get('event')
    value = request.json.get('value')
    if not cpf or not event or not value:
        return jsonify({'error': 'Please provide cpf, event and value'}), 400

    resp = client.put_item(
        TableName=tablename,
        Item={
            'cpf': {'S': cpf },
            'event': {'S': event },
            'value': {'S': value }
            
        }
    )

    return jsonify({
        'cpf': cpf,
        'event': event,
        'value': value
    })

# if __name__ == '__main__':
#     app.run()
