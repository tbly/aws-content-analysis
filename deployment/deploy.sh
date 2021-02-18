#!/bin/bash

echo "Log in to aws"
aws configure

echo "Create Amazon S3 Buckets"
REGION="ap-southeast-1"
UNIQUE_STRING=$RANDOM
TEMPLATE_BUCKET="content-analysis-templates-$UNIQUE_STRING"
CODE_BUCKET="content-analysis-code-$UNIQUE_STRING"
aws s3 mb s3://$TEMPLATE_BUCKET
aws s3 mb s3://$CODE_BUCKET-$REGION --region $REGION

echo "Run the build script"
cd /aws_content_analysis/deployment
./build-s3-dist.sh $TEMPLATE_BUCKET $CODE_BUCKET v1.0.2 $REGION

echo "Copy templates and code packages to S3"
aws s3 sync global-s3-assets s3://$TEMPLATE_BUCKET/aws-content-analysis/v1.0.2/
aws s3 sync regional-s3-assets s3://$CODE_BUCKET-$REGION/aws-content-analysis/v1.0.2/

echo "Deploy the stack"
EMAIL="lytieubang@gmail.com"
STACK_NAME="content-analysis"
aws cloudformation create-stack --stack-name $STACK_NAME --template-url https://"$TEMPLATE_BUCKET".s3.amazonaws.com/aws-content-analysis/v1.0.2/aws-content-analysis.template --region "$REGION" --parameters ParameterKey=DeployDemoSite,ParameterValue=true ParameterKey=AdminEmail,ParameterValue="$EMAIL" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

echo "ALL DONE!!! Awaiting for stack deployment completion, remember to look at content-analysis slack output for CloudFront URL and other settings"