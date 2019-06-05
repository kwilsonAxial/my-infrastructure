#!/bin/sh

PROJECT_NAME=my-app
BUCKET_NAME=axialhealthcare-analytics-testing

export AWS_DEFAULT_PROFILE=analytics

## Creates S3 bucket if it doesn't exist
echo "Checking if s3 bucket exists ..."
if ! aws s3api head-bucket --bucket $BUCKET_NAME 2>&1; 
then
    echo "Creating new s3 bucket ..."
    aws s3 mb s3://$BUCKET_NAME
        
    aws s3api wait \
        bucket-exists --bucket $BUCKET_NAME
        
    aws s3api put-public-access-block \
        --bucket $BUCKET_NAME \
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
        
fi

## S3 cloudformation deployments
echo "Uploading template files ..."
aws s3 cp \
    base/vpc-networking.yml \
    s3://$BUCKET_NAME/$PROJECT_NAME/cloudformation/vpc-networking.yml
    

echo "Checking if stack exists ..."
if ! aws cloudformation describe-stacks --stack-name $PROJECT_NAME ; 
then
    ## Create Stack
    echo "Creating new stack ..."
    aws cloudformation create-stack \
        --stack-name $PROJECT_NAME \
        --template-body file://deployment.yml \
        --parameters file://deployment.json
else
    ## Create Change Set
    echo "Creating a change set ..."
    CHANGE_SET_NAME="change-set-$(git rev-parse --short HEAD)"
    aws cloudformation create-change-set \
        --stack-name $PROJECT_NAME \
        --template-body file://deployment.yml \
        --parameters file://deployment.json \
        --change-set-name $CHANGE_SET_NAME
    
    aws cloudformation describe-change-set \
        --stack-name $PROJECT_NAME \
        --change-set-name $CHANGE_SET_NAME \
        | jq '.Changes[]'
    
    ## Update Stack
    echo "Updating existing stack ..."
    aws cloudformation update-stack \
        --stack-name $PROJECT_NAME \
        --template-body file://deployment.yml \
        --parameters file://deployment.json
fi

echo "Finished."