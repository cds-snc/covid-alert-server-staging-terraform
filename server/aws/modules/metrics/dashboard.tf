resource "aws_cloudwatch_dashboard" "metrics_ops_dashboard" {
  dashboard_name = "MetricsOps"

  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 3,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "${aws_dynamodb_table.aggregate_metrics.name}" ],
                    [ ".", "ConsumedReadCapacityUnits", ".", "${aws_dynamodb_table.raw_metrics.name}" ],
                    [ ".", "ConsumedWriteCapacityUnits", ".", "." ],
                    [ "AWS/ApiGateway", "Count", "ApiName", "${var.service_name}", "Resource", "/${var.service_name}", "Stage", "production", "Method", "POST" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ca-central-1",
                "stat": "Sum",
                "period": 60,
                "title": "Metrics - Dynamodb"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 9,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApiGateway", "4XXError", "ApiName", "${var.service_name}", "Resource", "/${var.service_name}", "Stage", "production", "Method", "POST" ],
                    [ ".", "Count", ".", ".", ".", ".", ".", ".", ".", ".", { "visible": false } ],
                    [ ".", "5XXError", ".", ".", ".", ".", ".", ".", ".", "." ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ca-central-1",
                "stat": "Sum",
                "period": 60,
                "title": "APIGW - 5xx & 4xx errors"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/ApiGateway", "Count", "ApiName", "${var.service_name}", "Resource", "/${var.service_name}", "Stage", "production", "Method", "POST" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ca-central-1",
                "stat": "Sum",
                "period": 60,
                "title": "API Gateway Count",
                "annotations": {
                    "horizontal": [
                        {
                            "visible": false,
                            "label": "Alarm",
                            "value": 35000
                        }
                    ]
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "AWS/ApiGateway", "Count", "ApiName", "${var.service_name}", "Resource", "/${var.service_name}", "Stage", "production", "Method", "POST" ],
                    [ ".", "5XXError", ".", ".", ".", ".", ".", ".", ".", "." ],
                    [ ".", "4XXError", ".", ".", ".", ".", ".", ".", ".", "." ]
                ],
                "view": "singleValue",
                "region": "ca-central-1",
                "period": 60,
                "singleValueFullPrecision": true,
                "stacked": false,
                "stat": "Sum",
                "setPeriodToTimeRange": true,
                "title": "Total for period"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 6,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Errors", "FunctionName", "${aws_lambda_function.aggregate_metrics.function_name}" ],
                    [ "...", "${var.service_name}"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "ca-central-1",
                "title": "Lambda Errors",
                "stat": "Sum",
                "period": 300
            }
        }
    ]
}
EOF
}