'use strict';

const
    AWS = require('aws-sdk'),
    dynamodb = new AWS.DynamoDB(),
    crypto = require('crypto');
    
const uuidv4 = () => {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
        (c ^ crypto.randomFillSync(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    );
}


exports.handler = async (event, context) => {

    const transactionStatus = {
        isBase64Encoded:  false
    };

    // expire after 24 hours
    const ttl = (Math.floor(Date.now()/1000) + 86400).toString();

    const params = {
        TableName: process.env.TABLE_NAME,
        Item : {
            "uuid": {
                S: uuidv4(),
            },
            "expdate" : {
                N: ttl,
            },
            "raw": {
                S: event.body,
            },
        },
    };

    try {

        await dynamodb.putItem(params).promise();
        transactionStatus.statusCode = 200;
        transactionStatus.body = JSON.stringify({ "status": "RECORD CREATED" });
    } catch (err) {
        console.error(`Upload faile ${err}`);
        transactionStatus.statusCode = 500;
        transactionStatus.body= JSON.stringify({ "status" : "UPLOAD FAILED" });
    }

    return transactionStatus;
};
