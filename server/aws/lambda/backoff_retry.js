'use strict';

const AWS = require("aws-sdk");
const https = require('https');
const agent = new https.Agent({
  keepAlive: true
});
const documentClient = new AWS.DynamoDB.DocumentClient({
  httpOptions: {
    agent
  }
});
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});

function calculateDelay(n){ 
  if (n === 1) {
    return 2
  }

  return n * n;
}

function buildDeadLetterMsg(payload, record, err){
  const delay = calculateDelay(record.MessageAttributes.DelaySeconds);

  return {
      DelaySeconds : delay,
      MessageBody : JSON.stringify(payload),
      QueueUrl : process.env.DEAD_LETTER_QUEUE_URL,
      MessageAttributes : {
          ErrorMsg: {
              DataType : "String",
              StringValue : err
          },
          DelaySeconds: {
              DataType : "Number",
              StringValue : delay
          }
      }
  }
}

async function sendToDeadLetterQueue(payload, record,  err) {
  const msg = buildDeadLetterMsg(payload, record, err);
  sqs.sendMessage(msg, (sqsErr, data) => {
    if (sqsErr){
      console.error(`Failed sending to dead letter queue: ${sqsErr}, failed msg: ${msg}`);
    }
  });

}

exports.handler = async function(event, context) {
  event.Records.forEach(record => {
    //read from dead letter queue
    const payload = JSON.parse(record.body);

    documentClient.update(payload, (err, data) => {
      if (err) {
        console.error(`Sending to dead letter queue ${err}`);
        await sendToDeadLetterQueue(payload, record, err);
      }
    });

  });
}
