'use strict';

const { handler } = require("./backoff_retry")
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

describe("handler", () => {
  let client
  let sqs

  beforeAll(async (done) => {
    client = new AWS.DynamoDB.DocumentClient()
    sqs = new AWS.SQS()
    jest.spyOn(console, 'error').mockImplementation(jest.fn());
    done();
  });

  it("updates the table with the payload", async () => {
    client.promise = jest.fn(async () => true)

    let documentA = {name: "a"}
    let documentB = {name: "b"}

    const event = {Records: [{ body: JSON.stringify(documentA) }, { body: JSON.stringify(documentB) }]}
    await handler(event)

    expect(client.update).toHaveBeenCalledWith(documentA)
    expect(client.update).toHaveBeenCalledWith(documentB)
  })

  it("call sendToDeadLetterQueue if there is an error with a squared DelaySeconds", async () => {
    process.env.DEAD_LETTER_QUEUE_URL = "foo"

    client.promise = jest.fn(async () => {throw "Error"})

    let documentA = {name: "a"}

    const event = {Records: [{ body: JSON.stringify(documentA), MessageAttributes: {DelaySeconds: 4} }]}
    await handler(event)

    let expectedMsg = {
      DelaySeconds: 16,
      MessageAttributes: {
        DelaySeconds: {
          DataType: "Number",
          StringValue: 16
        },
        ErrorMsg: {
          DataType: "String",
          StringValue: "Error"
        }
      },
      MessageBody: JSON.stringify(documentA),
      QueueUrl: process.env.DEAD_LETTER_QUEUE_URL
    }
    expect(sqs.sendMessage).toHaveBeenCalledWith(expectedMsg, expect.any(Function))

    delete process.env.DEAD_LETTER_QUEUE_URL
  })
})