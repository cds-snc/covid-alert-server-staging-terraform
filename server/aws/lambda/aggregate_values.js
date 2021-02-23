d'use strict';

const AWS = require("aws-sdk");

const sqs = new AWS.SQS({apiVersion: '2012-11-05'});
const METRIC_VERSION = 2;
const https = require('https');
const agent = new https.Agent({
  keepAlive: true
});

const documentClient = new AWS.DynamoDB.DocumentClient({
  httpOptions: {
    agent
  }
});


function p(val) { 
    return val || '*';
}

function createSK(date, appversion, appos, pl) {
    return `${pl.region}#${pl.identifier}#${date}#${appos}#${appversion}#${p(pl.pushnotification)}#${p(pl.frameworkenabled)}#${p(pl.state)}#${p(pl.hoursSinceExposureDetectedAt)}#${p(pl.count)}`;
}

function generatePayload(a) {
    return {
        TableName: "aggregate_metrics",
        Key: {
            "pk" : a.pk,
            "sk" : a.sk
        },
        UpdateExpression: `
        SET appversion = :appversion,
            appos = :appos,
            #region = :region,
            identifier = :identifier,
            version = :version,
            #count = :count,
            pushnotification = :pushnotification,
            frameworkenabled = :frameworkenabled,
            #state = :state,
            hoursSinceExposureDetectedAt = :hoursSinceExposureDetectedAt, 
            #date = :date
        ADD metricCount :metricCount`,
        ExpressionAttributeValues: {
            ':metricCount' : a.metricCount,
            ':appversion' : a.appversion,
            ':appos': a.appos,
            ':region': a.region,
            ':identifier': a.identifier,
            ':version': METRIC_VERSION,
            ':count': a.count || '',
            ':pushnotification': a.pushnotification || '',
            ':frameworkenabled': a.frameworkenabled || '',
            ':state': a.state || '',
            ':hoursSinceExposureDetectedAt': a.hoursSinceExposureDetectedAt || '',
            ':date' : a.date || '',
        },
        ExpressionAttributeNames: {
            '#region': 'region',
            '#count': 'count',
            '#state': 'state',
            '#date': 'date',
        }
    };
}

function pinDate(timestamp) {
    let d = new Date();
    d.setTime(timestamp);
    d.setHours(0,0,0,0);
    return d.toISOString().split('T')[0];
}

function aggregateEvents(event){
    const aggregates = {}; 
    event.Records.forEach((record) => {

        if(record.eventName === 'INSERT') {
            const raw = JSON.parse(record.dynamodb.NewImage.raw.S);
            raw.payload.forEach((pl) => {
                const date = pinDate(pl.timestamp);
                const sk = createSK(date, raw.appversion, raw.appos, pl);

                if (sk in aggregates){
                    aggregates[sk].metricCount = aggregates[sk].metricCount + 1;

                } else {

                    aggregates[sk] = {
                        ...pl,
                        pk: pl.region,
                        sk: createSK(date, raw.appversion, raw.appos, pl),
                        date: date,
                        appos: raw.appos,
                        appversion: raw.appversion,
                        metricCount: 1
                    };

                }

            });
        }
    });

    return aggregates;
}

function buildDeadLetterMsg(payload, err){
    return {
        DelaySeconds : 1,
        MessageBody : JSON.stringify(payload),
        QueueUrl : process.env.DEAD_LETTER_QUEUE_URL,
        MessageAttributes : {
            ErrorMsg: {
                DataType : "String",
                StringValue : err
            },
            DelaySeconds: { 
                DataType : "Number",
                StringValue : "1"
            }
        }
    };
}

function sendToDeadLetterQueue(payload, err) {
    const msg = buildDeadLetterMsg(payload, err);
    sqs.sendMessage(msg, (sqsErr, data) => {
        if (sqsErr) { 
            console.error(`Failed sending to Dead Letter Queue: ${sqsErr}, failed msg: ${msg}`);
        }
    });
}

exports.handler =  (event, context, callback) => {
    const aggregates = aggregateEvents(event);
    for (const aggregate in aggregates) {
        const payload = generatePayload(aggregates[aggregate]);
        documentClient.update(payload, (err, data) => { 
            if (err){ 
                console.error(`Failed updating sending to Dead Letter Queue ${err}`);
                sendToDeadLetterQueue(payload, err);
            }
        });
    }
    callback(null, "Aggregator is complete");
};
