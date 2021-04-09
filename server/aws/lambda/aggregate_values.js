'use strict';

const AWS = require("aws-sdk");
const sqs = new AWS.SQS({apiVersion: '2012-11-05'});
const METRIC_VERSION = 6;
const https = require('https');
const agent = new https.Agent({
    keepAlive: true
});

const documentClient = new AWS.DynamoDB.DocumentClient({
    httpOptions: {
        agent
    }
});

const p = (val) => {

    if (val === ''){ 
        return '*';
    }
    if (val === false){ 
        return false;
    }

    return val || '*';
}

const createSK = (date, appversion, appos, osversion, manufacturer, model, androidreleaseversion, pl) => {
    return `${pl.region}#${pl.identifier}#${date}#${appos}#${osversion}#${appversion}#${p(manufacturer)}#`+
    `${p(model)}#${p(androidreleaseversion)}#${p(pl.pushnotification)}#${p(pl.frameworkenabled)}#` +
    `${p(pl.state)}#${p(pl.hoursSinceExposureDetectedAt)}#${p(pl.count)}#${p(pl.duration)}#${p(pl.withDate)}#${p(pl.isUserExposed)}`;
}

const bucketCount = (count) => {

    if (count === undefined) {
        return undefined;
    }
    
    const parsedCount = parseInt(count,10);
    if (isNaN(parsedCount)) {
        return count;
    }

    if (parsedCount < 0) {
        console.error(`parsedCount is negative: ${parsedCount}`);
    }

    if (parsedCount === 0) {
        return '0';
    } else if(parsedCount < 6) {
        return '1-6';
    } else if (parsedCount < 12) {
        return '7-12';
    } else if (parsedCount < 30) {
        return '13-30';
    }
    return '30+';
}

const bucketDuration = (duration) => {
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

    if (parsedDuration === 0) {
        return '0';
    } else if (parsedDuration < 30) {
        return '< 30';
    } else if (parsedDuration < 60) {
        return '30 - 59';
    } else if (parsedDuration < 120) {
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

// Null Coalesce for optional attributes
const c = (val) => {
    return val || '';
}

const generatePayload = (a) => {
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
            model = :model,
            androidreleaseversion = :androidreleaseversion,
            version = :version,
            #count = :count,
            pushnotification = :pushnotification,
            frameworkenabled = :frameworkenabled,
            #state = :state,
            #status = :status,
            hoursSinceExposureDetectedAt = :hoursSinceExposureDetectedAt,
            #date = :date,
            #duration = :duration,
            withDate = :withDate,
            isUserExposed = :isUserExposed,
            metricCount = if_not_exists(metricCount, :start) + :metricCount`,
        ExpressionAttributeValues: {
            ':metricCount' : a.metricCount,
            ':appversion' : a.appversion,
            ':identifier': a.identifier,
            ':appos': a.appos,
            ':region': a.region,
            ':version': METRIC_VERSION,
            ':start': 0,
            ':osversion': c(a.osversion),
            ':count': c(a.count),
            ':pushnotification': c(a.pushnotification),
            ':frameworkenabled': c(a.frameworkenabled),
            ':state': c(a.state),
            ':status': c(a.status),
            ':hoursSinceExposureDetectedAt': c(a.hoursSinceExposureDetectedAt),
            ':date' : c(a.date),
            ':manufacturer': c(a.manufacturer),
            ':model': c(a.model),
            ':duration': c(a.duration),
            ':androidreleaseversion': c(a.androidreleaseversion),
            ':withDate': c(a.withDate),
            ':isUserExposed': c(a.isUserExposed)
        },
        // Reserved Keywords need to be handled here see:
        // https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html
        ExpressionAttributeNames: {
            '#region': 'region',
            '#count': 'count',
            '#state': 'state',
            '#status': 'status',
            '#date': 'date',
            '#duration': 'duration'
        }
    };
}

const pinDate = (timestamp) => {
    let d = new Date();
    d.setTime(timestamp);
    d.setHours(0,0,0,0);
    return d.toISOString().split('T')[0];
}

const aggregateEvents = (event) => {
    const aggregates = {}; 
    event.Records.forEach((record) => {
        try { 
            if(record.eventName === 'INSERT') {
                const raw = JSON.parse(record.dynamodb.NewImage.raw.S);
                raw.payload.forEach((pl) => {

                    // Skip Debug Events they currently aren't going to the aggregate_metrics table
                    if (pl.identifier === "ExposureNotificationCheck") {
                        return;
                    }
                    // bucket values to reduce possible permutations
                    const date = pinDate(pl.timestamp);
                    pl.count = bucketCount(pl.count);
                    pl.duration = bucketDuration(pl.durationInSeconds);

                    // deal with potentially missing data
                    const osversion = raw.osversion || '';
                    const manufacturer = raw.manufacturer || '';
                    const androidreleaseversion = raw.androidreleaseversion || '';
                    const model = raw.model || '';

                    const sk = createSK (
                            date,
                            raw.appversion,
                            raw.appos,
                            osversion,
                            manufacturer,
                            model,
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
                            model: model,
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

const buildDeadLetterMsg = (payload, err) => {
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

const sendToDeadLetterQueue = (payload, err) => {
    const msg = buildDeadLetterMsg(payload, err);
    sqs.sendMessage(msg, (sqsErr, data) => {
        if (sqsErr) { 
            console.error(`Failed sending to Dead Letter Queue: ${sqsErr}, failed msg: ${msg}`);
        }
    });
}

const handler = (event, context, callback) => {
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

exports.p = p;
exports.c = c;
exports.createSK = createSK;
exports.bucketCount = bucketCount;
exports.bucketDuration = bucketDuration;
exports.generatePayload = generatePayload;
exports.pinDate = pinDate;
exports.aggregateEvents = aggregateEvents;
exports.buildDeadLetterMsg = buildDeadLetterMsg;
exports.sendToDeadLetterQueue = sendToDeadLetterQueue;
exports.handler = handler;