'use strict';

const AWS = require("aws-sdk");
const documentClient = new AWS.DynamoDB.DocumentClient();
const crypto = require("crypto")

function createHash(sk, appversion, appos, pl) {
    return crypto.createHash('md5')
        .update(`${sk}_${pl.region}_${appversion}_${appos}_${pl.identifier}`)
        .digest('hex');
}

function generatePayload(a) {

    const updateCount = parseInt(a.count || 1,10);

    return {
        TableName: "aggregate_metrics",
        Key: {
            "pk" : a.pk,
            "date" : a.date
        },
        UpdateExpression: `
        SET #appversion = :appversion,
            #appos = :appos,
            #region = :region,
            #identifier = :identifier,
            #count = #count + :count`,
        ExpressionAttributeNames: {
            '#count' : 'count',
            "#appversion": 'appversion',
            "#appos": 'appos',
            "#region": 'region',
            "#identifier": 'identifier'
        },
        ExpressionAttributeValues: {
            ":appversion": a.appversion,
            ":appos": a.appos,
            ":region": a.region,
            ":identifier": a.identifier,
            ":count": updateCount,
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

        console.log('Stream record: ', JSON.stringify(record, null, 2));

        if(record.eventName === 'INSERT') {

            const raw = JSON.parse(record.dynamodb.NewImage.raw.S);
            raw.payload.forEach((pl) => {

                const sk = pinDate(pl.timestamp);
                const pk = createHash(sk, raw.appversion, raw.appos, pl);


                if (pk in aggregates){

                    aggregates[pk].count += pl.count;

                } else {

                    aggregates[pk] = {
                        ...pl,
                        pk: raw.pk,
                        date: sk,
                        appos: raw.appos,
                        appversion: raw.appversion,
                    };

                }

            });
        }
    });

    return aggregates;
}

exports.handler = async (event, context, callback) => {

    const aggregates = aggregateEvents(event);

    for (const aggregate in aggregates) {

        const payload = generatePayload(aggregates[aggregate]);
        try {
            await documentClient.update(payload).promise();
        }catch(err){
            console.log(err);
            //TODO: send to dead letter queue
        }
    }
};