'use strict';

const AWS = require("aws-sdk");
const documentClient = new AWS.DynamoDB.DocumentClient();
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
  try{
      const msg = buildDeadLetterMsg(payload, record, err);
      await sqs.sendMessage(msg);
  } catch (sqsErr){
      console.log(`Error: ${sqsErr}, failed msg: ${msg}`);
  }
}

exports.handler = async function(event, context) {
  event.Records.forEach(record => {
  //read from dead letter queue
    const payload = JSON.parse(record.body);

    try {
        await documentClient.update(payload).promise();
    }catch(err){
        console.log(err);
        await sendToDeadLetterQueue(payload, record, err);
    }
  });
}
