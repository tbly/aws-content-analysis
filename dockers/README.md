# AWS Content Analysis - Dockers

## Prepare the local DEV environment

### 1. Install docker and docker-compose
    
### 2. Update volumes path on dockers/docker-compose-dev.yml to correct folders

### 3. Update webapp/public/runtimeConfig.json file with slack output information like below (please note IDENTITY_POOL_ID is [region]:[UUID])

```
{"ELASTICSEARCH_ENDPOINT":"https://search-mie-es2-4opmjd4rebnbazpvfgvqxnb3xi.ap-southeast-1.es.amazonaws.com","WORKFLOW_API_ENDPOINT":"https://n9t25nqhlj.execute-api.ap-southeast-1.amazonaws.com/api/","DATAPLANE_API_ENDPOINT":"https://m57pozzcb8.execute-api.ap-southeast-1.amazonaws.com/api/","DATAPLANE_BUCKET":"content-analysis-dataplane-3u4l06zxq14","AWS_REGION":"ap-southeast-1","USER_POOL_ID":"ap-southeast-1_5bP66cDpk","USER_POOL_CLIENT_ID":"42m3rs0emtd9m8d3g92h751rld","IDENTITY_POOL_ID":"ap-southeast-1:b65945d0-58c4-4ef0-baab-2738e36fd109"}
```

### 4. Start dockers with docker-compose

```
sudo docker-compose -f dockers/docker-compose-dev.yml up --build
```

### 5. Stop dockers with docker-compose

```
sudo docker-compose -f dockers/docker-compose-dev.yml down
```

### 6. Login to console on docker

```
sudo docker exec -i -t aws-content-analysis-dev /bin/sh 
cd /aws_content_analysis/source/webapp
# npm install
npm run serve
````

## Run webapp in development environment

### 1. Go to folder 

```    
cd /aws_content_analysis/source/webapp
```

### 2. Install npm libraries

```    
npm install
```

### 3. Start DEV web server

```    
npn run serve
```

### 4. Compile and Deploy site files to S3

```
cd /aws_content_analysis/source/webapp
rm -rf dist/*
npm run build
npm run deploy
```


## Manual Deploy AWS Content Analysis

### 1. Log in to aws

You need to log in aws credential before able to run with CLI (ref: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

```
aws configure
```

Enter the information (access and secret keys get as instruction https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config)

```
AWS Access Key ID [None]: [your access key]
AWS Secret Access Key [None]: [your secret key]
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

### 2. Create Amazon S3 Buckets

You need 2 buckets to build and deploy this solution. One bucket holds CloudFormation template files and the other bucket holds code packages for AWS Lambda. The bucket for code packages needs to be in the same region where you intend to deploy this solution. For example, here's how you would make the buckets for the us-west-2 region:

```
REGION="ap-southeast-1"
UNIQUE_STRING=$RANDOM
TEMPLATE_BUCKET="content-analysis-templates-$UNIQUE_STRING"
CODE_BUCKET="content-analysis-code-$UNIQUE_STRING"
aws s3 mb s3://$TEMPLATE_BUCKET
aws s3 mb s3://$CODE_BUCKET-$REGION --region $REGION
```

### 3. Run the build script
Go to deployment folder

`cd /aws_content_analysis/deployment`

Run the build script, as shown below. Do not append `-$REGION` to the end of `$CODE_BUCKET`. 

`./build-s3-dist.sh $TEMPLATE_BUCKET $CODE_BUCKET v1.0.2 $REGION`

### 4. Copy templates and code packages to S3

The build script saves templates to `./global-s3-assets/` and code packages to `./regional-s3-assets`. Copy them to S3 like this:
```
aws s3 sync global-s3-assets s3://$TEMPLATE_BUCKET/aws-content-analysis/v1.0.2/
aws s3 sync regional-s3-assets s3://$CODE_BUCKET-$REGION/aws-content-analysis/v1.0.2/
```

### 5. Deploy the stack

Define the email address with which to receive credentials for accessing the web application then deploy the stack, like this:

```
EMAIL="lytieubang@gmail.com"
STACK_NAME="content-analysis"
aws cloudformation create-stack --stack-name $STACK_NAME --template-url https://"$TEMPLATE_BUCKET".s3.amazonaws.com/aws-content-analysis/v1.0.2/aws-content-analysis.template --region "$REGION" --parameters ParameterKey=DeployDemoSite,ParameterValue=true ParameterKey=AdminEmail,ParameterValue="$EMAIL" --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
```

### 6. Clean up

To remove the AWS resources created above, run the following commands: 

```
aws s3 rb s3://$TEMPLATE_BUCKET --force
aws s3 rb s3://$CODE_BUCKET-$REGION --force
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
```

Manual remove all relative data buckets on S3

## Run Deployment via scripts

### 1. Start the development docker

```
sudo docker-compose -f dockers/docker-compose-dev.yml up --build
```

### 2. Stop dockers with docker-compose (in case needed)

```
sudo docker-compose -f dockers/docker-compose-dev.yml down
```

### 3. Login to console on docker

```
sudo docker exec -i -t aws-content-analysis-dev /bin/sh 
```

### 4. Run deploy scripts

```
deactivate
cd /aws_content_analysis/deployment
./deploy.sh
```

### 5. Check stack deployment status on CloudFormation, collect neccessary data in Outputs tab

```
https://ap-southeast-1.console.aws.amazon.com/cloudformation/home
```

### 6. Clean up (if needed)
```
cd /aws_content_analysis/deployment
./cleanup.sh
``` 

### 7. Some useful services

#### a. Check logs on Cloudwatch

```
https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home
```

#### b. AWS lambda (can check, update scripts code directly)

```
https://ap-southeast-1.console.aws.amazon.com/lambda/home
```

#### c. S3 buckets

```
https://s3.console.aws.amazon.com/s3/home?region=ap-southeast-1
```