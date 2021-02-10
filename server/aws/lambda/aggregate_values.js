'use strict';

const AWS = require("aws-sdk");


exports.handler = (event, context, callback) => {

    event.Records.forEach((record) => {
        console.log('Stream record: ', JSON.stringify(record, null, 2));
      if(record.eventName === 'INSERT') { 
        console.log('uuid: ', record.dynamodb.NewImage.uuid.S);
        console.log('ttl: ', record.dynamodb.NewImage.uuid.N);
        console.log('raw: ', record.dynamodb.NewImage.uuid.S);

      }
    });
};  