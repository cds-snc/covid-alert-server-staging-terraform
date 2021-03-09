'use strict';

const lambda = require("./aggregate_values")
const AWS = require('aws-sdk');

jest.mock("aws-sdk", () => {
  const mockDynamoDb = {
    update: jest.fn().mockReturnThis(),
    promise: jest.fn(),
  };

  const mockSQS = {
    sendMessage: jest.fn().mockReturnThis(),
    promise: jest.fn(),
  };

  return {
    __esModule: true,
    DynamoDB: {
      DocumentClient: jest.fn(() => mockDynamoDb)
    },
    SQS: jest.fn(() => mockSQS),
  };
});

jest.spyOn(console, 'error').mockImplementation(jest.fn());

describe("p", () => {
  it("returns a * if the value is an empty string", () => {
    expect(lambda.p("")).toStrictEqual("*")
  })

  it("returns the value if the value is defined", () => {
    expect(lambda.p("foo")).toStrictEqual("foo")
  })

  it("returns * if the value is undefined", () => {
    expect(lambda.p(undefined)).toStrictEqual("*")
  })
})

describe("createSK", () => {
  it("concats 14 values into a key joined by a #", () => {
    let date = "a"
    let appversion = "b"
    let appos = "c"
    let osversion = "d"
    let manufacturer = "e"
    let model = "model"
    let androidreleaseversion = "f"
    let pl = {
      region: "g",
      identifier: "h",
      pushnotification: "i",
      frameworkenabled: "j",
      state: "k",
      hoursSinceExposureDetectedAt: "l",
      count: "m",
      duration: "n"
    }
    const result = lambda.createSK(date, appversion, appos, osversion, manufacturer, model, androidreleaseversion, pl)
    expect(result).toStrictEqual("g#h#a#c#d#b#e#model#f#i#j#k#l#m#n")
    expect(result.split("#").length).toStrictEqual(15)
  })

  it("replaces certain values with stars", () => {
    let date = "a"
    let appversion = "b"
    let appos = "c"
    let osversion = "d"
    let manufacturer = undefined
    let model = undefined
    let androidreleaseversion = undefined
    let pl = {
      region: "g",
      identifier: "h",
      pushnotification: undefined,
      frameworkenabled: undefined,
      state: undefined,
      hoursSinceExposureDetectedAt: undefined,
      count: undefined,
      duration: undefined
    }
    const result = lambda.createSK(date, appversion, appos, osversion, manufacturer, model, androidreleaseversion, pl)
    expect(result).toStrictEqual("g#h#a#c#d#b#*#*#*#*#*#*#*#*#*")
    expect(result.split("#").length).toStrictEqual(15)
  })
})

describe("bucketCount", () => {
  it("returns undefined if the value passed to it is undefined", () => {
    expect(lambda.bucketCount(undefined)).toStrictEqual(undefined)
  })

  it("returns what is passed if it can't parse the number", () => {
    expect(lambda.bucketCount("a")).toStrictEqual("a")
  })

  it("returns 1-6 if the number is negative or zero", () => {
    expect(lambda.bucketCount("0")).toStrictEqual("1-6")
  })

  it("returns 7-12 if the number is 6", () => {
    expect(lambda.bucketCount("6")).toStrictEqual("7-12")
  })

  it("returns 13-30 if the number is 12", () => {
    expect(lambda.bucketCount("12")).toStrictEqual("13-30")
  })

  it("returns 30+ if the number is 30", () => {
    expect(lambda.bucketCount("30")).toStrictEqual("30+")
  })
})

describe("bucketDuration", () => {
  it("returns undefined if the value passed to it is undefined", () => {
    expect(lambda.bucketDuration(undefined)).toStrictEqual(undefined)
  })

  it("returns what is passed if it can't parse the number", () => {
    expect(lambda.bucketDuration("a")).toStrictEqual("a")
  })

  it("returns < 30 if the number is negative or zero", () => {
    expect(lambda.bucketDuration("0")).toStrictEqual("< 30")
  })

  it("returns 30 - 59 if the number is 59", () => {
    expect(lambda.bucketDuration("59")).toStrictEqual("30 - 59")
  })

  it("returns 1:00 min - 1:59 min if the number is 119", () => {
    expect(lambda.bucketDuration("119")).toStrictEqual("1:00 min - 1:59 min")
  })

  it("returns 2:00 min - 3:59 min if the number is 239", () => {
    expect(lambda.bucketDuration("239")).toStrictEqual("2:00 min - 3:59 min")
  })

  it("returns 4:00 min - 5:59 min if the number is 359", () => {
    expect(lambda.bucketDuration("359")).toStrictEqual("4:00 min - 5:59 min")
  })

  it("returns 6:00 min - 7:59 min if the number is 479", () => {
    expect(lambda.bucketDuration("479")).toStrictEqual("6:00 min - 7:59 min")
  })

  it("returns 8:00 min - 9:59 min if the number is 600", () => {
    expect(lambda.bucketDuration("600")).toStrictEqual("8:00 min - 9:59 min")
  })

  it("returns > 10:00 min if the number is 601", () => {
    expect(lambda.bucketDuration("601")).toStrictEqual("> 10:00 min")
  })
})

describe("generatePayload", () => {
  it("generates a DynamoDB payload from an object", () => {
    let intialPayload = {
      date: "a",
      appversion: "b",
      appos: "c",
      osversion: "d",
      manufacturer: "e",
      model: "model",
      androidreleaseversion: "f",
      region: "g",
      identifier: "h",
      pushnotification: "i",
      frameworkenabled: "j",
      state: "k",
      hoursSinceExposureDetectedAt: "l",
      count: "m",
      duration: "n",
      metricCount: "o",
      pk: "p",
      sk: "q"
    }

    let expectedPayload = {
      TableName: "aggregate_metrics",
      Key: {
        "pk": intialPayload.pk,
        "sk": intialPayload.sk
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
            hoursSinceExposureDetectedAt = :hoursSinceExposureDetectedAt,
            #date = :date,
            #duration = :duration,
            metricCount = if_not_exists(metricCount, :start) + :metricCount`,
      ExpressionAttributeValues: {
        ':metricCount': intialPayload.metricCount,
        ':appversion': intialPayload.appversion,
        ':appos': intialPayload.appos,
        ':region': intialPayload.region,
        ':osversion': intialPayload.osversion,
        ':identifier': intialPayload.identifier,
        ':version': 4,
        ':count': intialPayload.count,
        ':pushnotification': intialPayload.pushnotification,
        ':frameworkenabled': intialPayload.frameworkenabled,
        ':state': intialPayload.state,
        ':hoursSinceExposureDetectedAt': intialPayload.hoursSinceExposureDetectedAt,
        ':date': intialPayload.date,
        ':start': 0,
        ':manufacturer': intialPayload.manufacturer,
        ':model': intialPayload.model,
        ':duration': intialPayload.duration,
        ':androidreleaseversion': intialPayload.androidreleaseversion
      },
      ExpressionAttributeNames: {
        '#region': 'region',
        '#count': 'count',
        '#state': 'state',
        '#date': 'date',
        '#duration': 'duration'
      }
    }

    expect(lambda.generatePayload(intialPayload)).toStrictEqual(expectedPayload)
  })
})

describe("pinDate", () => {
  it("rounds a unix timestamp to the current UTC date", () => {
    expect(lambda.pinDate(1615231884409)).toStrictEqual("2021-03-08")
  })
})

describe("aggregateEvents", () => {
  it("returns an empty object if it fails to aggregate events", () => {
    let event = { Records: ["a"] }
    expect(lambda.aggregateEvents(event)).toStrictEqual({})
  })

  it("aggregates event records and returns them as an object", () => {
    let payload = {
      osversion: "a",
      manufacturer: "b",
      model: "model",
      androidreleaseversion: "c",
      appversion: "d",
      appos: "e",
      payload: [
        {
          timestamp: 1615231884409,
          region: "g",
          identifier: "h",
          pushnotification: "i",
          frameworkenabled: "j",
          state: "k",
          hoursSinceExposureDetectedAt: "l",
          count: "m",
          duration: "n"
        }
      ]
    }
    let event = {
      Records: [{
        eventName: "INSERT",
        dynamodb: { NewImage: { raw: { S: JSON.stringify(payload) } } }
      }]
    }

    let expectedEvents = {
      "g#h#2021-03-08#e#a#d#b#model#c#i#j#k#l#m#n": {
        "androidreleaseversion": "c",
        "appos": "e",
        "appversion": "d",
        "count": "m",
        "date": "2021-03-08",
        "duration": "n",
        "frameworkenabled": "j",
        "hoursSinceExposureDetectedAt": "l",
        "identifier": "h",
        "manufacturer": "b",
        "model": "model",
        "metricCount": 1,
        "osversion": "a",
        "pk": "g",
        "pushnotification": "i",
        "region": "g",
        "sk": "g#h#2021-03-08#e#a#d#b#model#c#i#j#k#l#m#n",
        "state": "k",
        "timestamp": 1615231884409,
      }
    }
    expect(lambda.aggregateEvents(event)).toStrictEqual(expectedEvents)
  })

  it("aggregates multiple event records and returns them as an object", () => {
    let payload = {
      osversion: "a",
      manufacturer: "b",
      model: "model",
      androidreleaseversion: "c",
      appversion: "d",
      appos: "e",
      payload: [
        {
          timestamp: 1615231884409,
          region: "g",
          identifier: "h",
          pushnotification: "i",
          frameworkenabled: "j",
          state: "k",
          hoursSinceExposureDetectedAt: "l",
          count: "m",
          duration: "n"
        }
      ]
    }
    let event = {
      Records: [{
        eventName: "INSERT",
        dynamodb: { NewImage: { raw: { S: JSON.stringify(payload) } } }
      }, {
        eventName: "INSERT",
        dynamodb: { NewImage: { raw: { S: JSON.stringify(payload) } } }
      }]
    }

    let expectedEvents = {
      "g#h#2021-03-08#e#a#d#b#model#c#i#j#k#l#m#n": {
        "androidreleaseversion": "c",
        "appos": "e",
        "appversion": "d",
        "count": "m",
        "date": "2021-03-08",
        "duration": "n",
        "frameworkenabled": "j",
        "hoursSinceExposureDetectedAt": "l",
        "identifier": "h",
        "manufacturer": "b",
        "model": "model",
        "metricCount": 2,
        "osversion": "a",
        "pk": "g",
        "pushnotification": "i",
        "region": "g",
        "sk": "g#h#2021-03-08#e#a#d#b#model#c#i#j#k#l#m#n",
        "state": "k",
        "timestamp": 1615231884409,
      }
    }
    expect(lambda.aggregateEvents(event)).toStrictEqual(expectedEvents)
  })
})

describe("buildDeadLetterMsg", () => {
  it("returns an object interpolating various data", () => {
    process.env.DEAD_LETTER_QUEUE_URL = "foo"

    let payload = {a: true}
    let err = "ouch"

    let expectedReturn = {
      DelaySeconds: 1,
      MessageBody: JSON.stringify(payload),
      QueueUrl: process.env.DEAD_LETTER_QUEUE_URL,
      MessageAttributes: {
        ErrorMsg: {
          DataType: "String",
          StringValue: err
        },
        DelaySeconds: {
          DataType: "Number",
          StringValue: "1"
        }
      }
    };

    expect(lambda.buildDeadLetterMsg(payload, err)).toStrictEqual(expectedReturn)
    delete process.env.DEAD_LETTER_QUEUE_URL
  })
})

describe("sendToDeadLetterQueue", () => {
  let sqs

  beforeAll(async (done) => {
    sqs = new AWS.SQS()
    done();
  });

  it("sends a dead letter message", () => {
    let payload = {a: true}
    let err = "ouch"
    lambda.sendToDeadLetterQueue(payload, err)
    expect(sqs.sendMessage).toHaveBeenCalledTimes(1)
  })
})

describe("handler", () => {
  let client
  let sqs

  beforeAll(async (done) => {
    client = new AWS.DynamoDB.DocumentClient()
    sqs = new AWS.SQS()
    done();
  });

  it("send 'Aggregator complete but failed to parse' and 'Aggregator is complete' to callback if there is an error", () => {

    let callback = jest.fn()
    const event = {}
    lambda.handler(event, false, callback)

    expect(callback).toHaveBeenCalledWith(null, 'Aggregator complete but failed to parse')
    expect(callback).toHaveBeenCalledWith(null, 'Aggregator is complete')
  })

  
  it("it calls document update if the payload is valid and aggregated succesfully", () => {

    let callback = jest.fn()
    let payload = {
      osversion: "a",
      manufacturer: "b",
      model: "model",
      androidreleaseversion: "c",
      appversion: "d",
      appos: "e",
      payload: [
        {
          timestamp: 1615231884409,
          region: "g",
          identifier: "h",
          pushnotification: "i",
          frameworkenabled: "j",
          state: "k",
          hoursSinceExposureDetectedAt: "l",
          count: "m",
          duration: "n"
        }
      ]
    }
    let event = {
      Records: [{
        eventName: "INSERT",
        dynamodb: { NewImage: { raw: { S: JSON.stringify(payload) } } }
      }]
    }

    lambda.handler(event, false, callback)
    expect(client.update).toHaveBeenCalledTimes(1)
    expect(callback).not.toHaveBeenCalledWith(null, 'Aggregator complete but failed to parse')
    expect(callback).toHaveBeenCalledWith(null, 'Aggregator is complete')
  })
})