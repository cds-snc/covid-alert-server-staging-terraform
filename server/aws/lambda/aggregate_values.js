'use strict';

const AWS = require("aws-sdk");
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});
const METRIC_VERSION = 3;
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

    if (val === ''){ 
        return '*';
    }

    return val || '*';
}

function createSK(date, appversion, appos, osversion, manufacturer, androidreleaseversion, pl) {
    return `${pl.region}#${pl.identifier}#${date}#${appos}#${osversion}#${appversion}#${p(manufacturer)}#${p(androidreleaseversion)}#${p(pl.pushnotification)}#${p(pl.frameworkenabled)}#${p(pl.state)}#${p(pl.hoursSinceExposureDetectedAt)}#${p(pl.count)}#${p(pl.duration)}`;
}

function bucketCount(count) {

    if (count === undefined) {
        return undefined;
    }
    
    const parsedCount = parseInt(count,10);
    if (isNaN(parsedCount)) {
        return count;
    }

    if (parsedCount <= 0) {
        console.error(`parsedCount is negative: ${parsedCount}`);
    }

    if (parsedCount < 6) {
        return '1-6';
    } else if (parsedCount < 12) {
        return '7-12';
    } else if (parsedCount < 30) {
        return '13-30';
    }
    return '30+';
}

function bucketDuration(duration) {
    if (duration === undefined){
        return undefined;
    }
    
    const parsedDuration = parseFloat(duration,10);
    if (isNaN(parsedDuration)) {
        return duration;
    }

    if (parsedDuration <= 0) {
        console.error(`parsedDuration is negative: ${parsedDuration}`);
    }

    if (parsedDuration < 30) {
        return '< 30';
    } else if (parsedDuration < 60) {
        return '30 - 59';
    } else if (parsedDuration < 140) {
        return '1:00 min - 1:59 min';
    } else if (parsedDuration < 240) {
        return '2:00 min - 3:59 min';
    } else if (parsedDuration < 360) {
        return '4:00 min - 5:59 min';
    } else if (parsedDuration < 480) {
        return '6:00 min - 7:59 min';
    } else if (parsedDuration <= 600) {
        return '8:00 min - 9:59 min';
    }

    console.error(`parsedDuration is greater then 10 minutes: ${parsedDuration}`)
    return '> 10:00 min';
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
            osversion = :osversion,
            manufacturer = :manufacturer,
            androidreleaseversion = :androidreleaseversion,
            version = :version,
            #count = :count,
            pushnotification = :pushnotification,
            frameworkenabled = :frameworkenabled,
            #state = :state,
            hoursSinceExposureDetectedAt = :hoursSinceExposureDetectedAt,
            #date = :date,
            #duration = :duration,
            metricCount = if_not_exists(metricCount, :start) + :metricCount`,
        ExpressionAttributeValues: {
            ':metricCount' : a.metricCount,
            ':appversion' : a.appversion,
            ':appos': a.appos,
            ':region': a.region,
            ':osversion': a.osversion || '',
            ':identifier': a.identifier,
            ':version': METRIC_VERSION,
            ':count': a.count || '',
            ':pushnotification': a.pushnotification || '',
            ':frameworkenabled': a.frameworkenabled || '',
            ':state': a.state || '',
            ':hoursSinceExposureDetectedAt': a.hoursSinceExposureDetectedAt || '',
            ':date' : a.date || '',
            ':start': 0,
            ':manufacturer': a.manufacturer || '',
            ':duration': a.duration || '',
            ':androidreleaseversion': a.androidreleaseversion || ''
        },
        ExpressionAttributeNames: {
            '#region': 'region',
            '#count': 'count',
            '#state': 'state',
            '#date': 'date',
            '#duration': 'duration'
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
        try { 
            if(record.eventName === 'INSERT') {
                const raw = JSON.parse(record.dynamodb.NewImage.raw.S);
                raw.payload.forEach((pl) => {

                    // bucket values to reduce possible permutations
                    const date = pinDate(pl.timestamp);
                    pl.count = bucketCount(pl.count);
                    pl.duration = bucketDuration(pl.duration);

                    // deal with potentially missing data
                    const osversion = raw.osversion || '';
                    const manufacturer = raw.manufacturer || '';
                    const androidreleaseversion = raw.androidreleaseversion || '';

                    const sk = createSK (
                            date,
                            raw.appversion,
                            raw.appos,
                            osversion,
                            manufacturer,
                            androidreleaseversion,
                            pl
                        );

                    if (sk in aggregates){

                        aggregates[sk].metricCount = aggregates[sk].metricCount + 1;

                    } else {

                        aggregates[sk] = {
                            ...pl,
                            pk: pl.region,
                            sk: sk,
                            date: date,
                            appos: raw.appos,
                            appversion: raw.appversion,
                            osversion: osversion,
                            metricCount: 1,
                            manufacturer: manufacturer,
                            androidreleaseversion: androidreleaseversion
                        };

                    }

                });
            }

        } catch(err) {
            console.error(`issue parsing event: ${err}`);
            //TODO: send to s3 bucket
            console.error(`payload uuid: ${record.dynamodb.NewImage.uuid.S}`)
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

    try {

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

    } catch(err){

        //TODO: send to s3 bucket
        console.error(`failed event: ${JSON.stringify(err)}`);
        callback(null, "Aggregator complete but failed to parse");

    }

    callback(null, "Aggregator is complete");
};
