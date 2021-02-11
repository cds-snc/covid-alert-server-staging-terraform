'use strict';

const AWS = require("aws-sdk");
const documentClient = new AWS.DynamoDB.DocumentClient();
const crypto = require("crypto")
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});

function createHash(sk, appversion, appos, pl) {
    return crypto.createHash('md5')
        .update(`${sk}_${pl.region}_${appversion}_${appos}_${pl.identifier}`)
        .digest('hex');
}

function generatePayload(a) {

    const updateCount = parseInt(a.count || 1, 10);

    return {
        TableName: "aggregate_metrics",
        Key: {
            "pk" : a.pk,
            "date" : a.date.getTime()
        },
        UpdateExpression: `
        SET #appversion = :appversion,
            #appos = :appos,
            #region = :region,
            #identifier = :identifier,
            #pushnotification = :pushnotification,
            #frameworkenabled = :frameworkenabled,
            #state = :state,
            #hoursSinceExposureDetectedAt = :hoursSinceExposureDetectedAt
        ADD #count :count`,
        ExpressionAttributeNames: {
            "#appversion": 'appversion',
            "#appos": 'appos',
            "#region": 'region',
            "#identifier": 'identifier',
            '#count' : 'count',
            '#pushnotification': 'pushnotification',
            '#frameworkenabled': 'frameworkenabled',
            '#state': 'state',
            '#hoursSinceExposureDetectedAt': 'hoursSinceExposureDetectedAt'
        },
        ExpressionAttributeValues: {
            ":appversion": a.appversion,
            ":appos": a.appos,
            ":region": a.region,
            ":identifier": a.identifier,
            ":count": updateCount,
            ':pushnotification': a.pushnotification || '',
            ':frameworkenabled': a.frameworkenabled || '',
            ':state': a.state || '',
            ':hoursSinceExposureDetectedAt': a.hoursSinceExposureDetectedAt || ''
        }
    };
}

function pinDate(timestamp) {
    let d = new Date();
    d.setTime(timestamp);
    d.setHours(0,0,0,0);
    return d;
}

function aggregateEvents(event){
    const aggregates = {}; 
    event.Records.forEach((record) => {

        if(record.eventName === 'INSERT') {

            const raw = JSON.parse(record.dynamodb.NewImage.raw.S);
            raw.payload.forEach((pl) => {

                const sk = pinDate(pl.timestamp);
                const pk = createHash(sk, raw.appversion, raw.appos, pl);


                if (pk in aggregates){

                    aggregates[pk].count = parseInt(aggregates[pk].count, 10) + parseInt(pl.count || 1,10);

                } else {

                    const aggregate =  {
                        ...pl,
                        pk: pk,
                        date: sk,
                        appos: raw.appos,
                        appversion: raw.appversion,
                    };
                    aggregates[pk] =aggregate;

                }

            });
        }
    });

    return aggregates;
}

function buildDeadLetterMsg(payload, err){
    return {
        DelaySeconds = 1,
        MessageBody = JSON.stringify(payload),
        QueueUrl = process.env.DEAD_LETTER_QUEUE_URL,
        MessageAttributes = {
            "ErrorMsg": {
                DataType = "string",
                StringValue = err
            }
        }
    }

}

function sendToDeadLetterQueue(payload, err) {
    try{
        const msg = buildDeadLetterMsg(payload,err);
        sqs.sendMessage(msg);
    } catch (sqsErr){
        console.log(`Error: ${sqsErr}, failed msg: ${msg}`);
    }
}

exports.handler = async (event, context, callback) => {

    const aggregates = aggregateEvents(event);
    for (const aggregate in aggregates) {

        const payload = generatePayload(aggregates[aggregate]);
        try {
            await documentClient.update(payload).promise();
        }catch(err){
            console.log(err);
            sendToDeadLetterQueue(payload);
        }
    }
};