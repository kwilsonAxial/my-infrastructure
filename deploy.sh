#!/bin/sh

PROJECT_NAME=my-app
BUCKET_NAME=axialhealthcare-analytics-testing

## Creates S3 bucket if it doesn't exist
if ! aws s3api head-bucket --bucket $BUCKET_NAME --profile analytics 2>&1; 
then
    aws s3 mb s3://$BUCKET_NAME --profile analytics --region us-west-1
    aws s3api wait bucket-exists --bucket $BUCKET_NAME --profile analytics
    aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" --profile analytics
fi

## S3 cloudformation deployments
aws s3 cp vpc-networking.yml s3://$BUCKET_NAME/$PROJECT_NAME/cloudformation/vpc-networking.yml --profile analytics