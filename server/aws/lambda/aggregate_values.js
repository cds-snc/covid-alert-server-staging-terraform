'use strict';

const AWS = require("aws-sdk");
const documentClient = new AWS.DynamoDB.DocumentClient();
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});

function createSK(appversion, appos, pl) {
    return `${pl.region}#${pl.identifier}#${pl.date}#${appos}#${appversion}`
}

function generatePayload(a) {
    return {
        TableName: "aggregate_metrics",
        Key: {
            "pk" : a.pk,
            "sk" : a.sk
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
            '#hoursSinceExposureDetectedAt': 'hoursSinceExposureDetectedAt',
            '#date': 'date'
        },
        ExpressionAttributeValues: {
            ":appversion": a.appversion,
            ":appos": a.appos,
            ":region": a.region,
            ":identifier": a.identifier,
            ":count": a.count,
            ':pushnotification': a.pushnotification || '',
            ':frameworkenabled': a.frameworkenabled || '',
            ':state': a.state || '',
            ':hoursSinceExposureDetectedAt': a.hoursSinceExposureDetectedAt || '',
            ':date': a.date
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
                
                const pk = pl.region;

                // Count should be 1 if not there
                pl.count = parseInt(pl.count || 1, 10);

                if (pk in aggregates){

                    aggregates[pk].count = aggregates[pk].count + pl.count;

                } else {

                    aggregates[pk] = {
                        ...pl,
                        pk: pl.region,
                        sk: createhash(raw.appversion, raw.appos, pl),
                        date: pinDate(pl.timestamp),
                        appos: raw.appos,
                        appversion: raw.appversion,
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
                StringValue : 1 
            }
        }
    }
}

async function sendToDeadLetterQueue(payload, err) {
    let msg;
    try{

        msg = buildDeadLetterMsg(payload,err);
        await sqs.sendMessage(msg).promise();

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
            await sendToDeadLetterQueue(payload)

        }
    }
}
