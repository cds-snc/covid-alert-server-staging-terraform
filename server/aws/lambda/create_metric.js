'use strict';

const
    AWS = require('aws-sdk'),
    S3 = new AWS.S3(),
    crypto = require('crypto');
    
const uuidv4 = () => {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.randomFillSync(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}

const todaysDate = () => {
    let today = new Date();
    return today.toISOString().split('T')[0]);
}

exports.handler = async (event, context) => {

    const bucket = process.env.dataBucket;
    const filePath = process.env.fileLoca;
    const filename = uuidv4();
    let transactionStatus;

    const bucketParams = {
        Bucket: `${bucket}/${filePath}/${todaysDate()}`,
        Key: `${filename}.json`,
        Body: JSON.stringify(event),
        ServerSideEncryption: 'AES256'
    };

    /* The puObject call forces a promise because the result returned may not be a promise.  */
    try {
        const resp = await S3.putObject(bucketParams).promise();
        transactionStatus = { "status": "RECORD CREATED", "key": filename};
    } catch (err) {
        transactionStatus = { "status": "UPLOAD FAILED"};
    }

    return transactionStatus;
};
