# sam manual

[ref] https://catalog.us-east-1.prod.workshops.aws/workshops/d21ec850-bab5-4276-af98-a91664f8b161/en-US

## sam local test

## sam make event file
sam local generate-event apigateway aws-proxy --method GET --path /hello > event.json


## cache clean and build
rm -rf .aws-sam && sam build

## invoke
sam local invoke HelloWorldFunction -e event.json

## Create table
~~~
aws dynamodb create-table \
  --table-name sam-app-hjoon-1210 \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url http://172.31.1.81:8000
~~~

## list table
~~~
aws dynamodb list-tables --endpoint-url http://172.31.1.81:8000
~~~

## delete table 
~~~
aws dynamodb delete-table \
  --table-name sam-app-hjoon-1210 \
  --endpoint-url http://172.31.1.81:8000
~~~

## local service test
- You start your serverless application locally
~~~
sam local start-api
~~~
- the 


