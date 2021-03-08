'use strict';

const { handler } = require("./create_metric")
const AWS = require('aws-sdk');

jest.mock("aws-sdk", () => {
  const mockDynamoDb = {
      putItem: jest.fn().mockReturnThis(),
      promise: jest.fn(),
  };
  return {
      __esModule: true,
      DynamoDB: jest.fn(() => mockDynamoDb),
  };
});


describe("handler", () => {
  let client

  beforeAll(async (done) => {
    client = new AWS.DynamoDB();
    jest.spyOn(console, 'error').mockImplementation(jest.fn());
    done();
   });

  it("returns a 500 error code if the putItem fails", async () => {
    client.promise = jest.fn(async () => {throw "Error"})

    const event = {body: ""}
    const response = await handler(event)

    expect(response).toStrictEqual({
      isBase64Encoded: false,
      statusCode: 500,
      body: JSON.stringify({ "status" : "UPLOAD FAILED" })
    })
  })

  it("returns a 200 code if the putItem succeeds", async () => {
    client.promise = jest.fn(async () => true)

    const event = {body: ""}
    const response = await handler(event)

    expect(response).toStrictEqual({
      isBase64Encoded: false,
      statusCode: 200,
      body: JSON.stringify({ "status" : "RECORD CREATED" })
    })
  })

  it("saves the event body with a random UUID and a TTL", async () => {
    process.env.TABLE_NAME = "foo"

    client.promise = jest.fn(async () => true)

    const event = {body: ""}
    const response = await handler(event)

    expect(client.putItem).toHaveBeenCalledWith(expect.objectContaining({
      TableName: process.env.TABLE_NAME,
      Item: {
        expdate: {N: expect.any(String)},
        raw: {S: event.body},
        uuid: {S: expect.any(String)},
      }
    }))

    expect(response).toStrictEqual({
      isBase64Encoded: false,
      statusCode: 200,
      body: JSON.stringify({ "status" : "RECORD CREATED" })
    })

    delete process.env.TABLE_NAME
  })
})