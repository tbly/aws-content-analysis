#!/bin/bash

echo "Clean up"
aws s3 rb s3://$TEMPLATE_BUCKET --force
aws s3 rb s3://$CODE_BUCKET-$REGION --force
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION