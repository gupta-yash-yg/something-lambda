def f1(event, context):
    print(event)
    return {
        "statusCode": 200,
        "body": "Test"
    }
