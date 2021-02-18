# AWS Content Analysis 

Amazon Web Services (AWS) offers powerful and cost-effective services to help customers process, analyze, and extract meaningful data from video files. Customers who want to obtain a broader understanding of their media libraries can use these services to develop solutions to analyze and extract valuable metadata from their video files. Customers can also use various machine learning tools to develop their own analytical solutions in the AWS Cloud. However, using these services together in a single unified application that combines insights derived from multiple AWS AI services requires a lot of custom integration work.

The AWS Content Analysis solution combines Amazon Rekognition, Amazon Transcribe, Amazon Translate, and Amazon Comprehend to offer a suite of comprehensive capabilities to analyze your media content. Amazon Rekognition provides highly accurate object, scene, and activity detection; person identification and pathing; and celebrity recognition in videos and images. Amazon Transcribe provides an automatic speech recognition service while Amazon Translate translates your content between languages. Amazon Comprehend extracts key phrases and entities from transcripts from their media files in their AWS accounts without machine learning expertise.

The AWS Content Analysis solution is a tailored application based on the open source project [Media Insights Engine (MIE)](https://github.com/awslabs/aws-media-insights-engine). The Media Insights Engine provides a framework to make it easier for developers to build applications that transform or analyze videos on AWS. For more information about how the AWS Content Analysis Solution can be modified to suite for your own needs, be sure to check out the documentation for MIE.

# COST:

Most AWS accounts include a free tier for the services used in this solution. However, if your usage exceeds the free tier allotments then you will be responsible for the cost of the AWS services used while running this solution.

The cost of this app is dominated by AWS Rekognition and Amazon Elasticsearch. A good rule of thumb is that videos will cost about $0.50 / minute to process. That can vary between $0.10 / minute and $0.60 / minute depending on video content. If you disable Rekognition in your workflow configuration then these costs will be more like $0.04 / minute. Data storage will generally be $10/day regardless of the quantity or type of video content. 

While the costs of processing a video occurs as a one-time expense after uploading the video, the costs for data storage occur daily, as shown in the following screenshot from AWS Cost Explorer:

![](/doc/images/costs_movie.png)

# USER'S GUIDE:

1. Upload videos in the upload button. Currently only "mp4" file types are supported. Once the upload completes, it will automatically be processed with the MieComplete Workflow (i.e. the Kitchen sink) which includes every media analysis operator in MIE.
2. The workflow status will be shown in the Collection view. Status will be updated when you reload the page.
3. The search field in the Collection view searches the full metadata database in Elasticsearch. Everything you see in the analysis page is searchable. Even data that is excluded by the threshold you set in the Confidence slider is searchable. Search queries must use valid Lucene syntax.

Here are some sample searches:

* Since Content Moderation returns a "Violence" label when it detects violence in a video, you can search for any video containing violence simply with: `Violence`
* Search for videos containing violence with a 80% confidence threshold: `Violence AND Confidence:>80` 
* The previous queries may match videos whose transcript contains the word "Violence". You can restrict your search to only Content Moderation results, like this: `Operator:content_moderation AND (Name:Violence AND Confidence:>80)`
* To search for Violence results in Content Moderation and guns or weapons identified by Label Detection, try this: `(Operator:content_moderation AND Name:Violence AND Confidence:>80) OR (Operator:label_detection AND (Name:Gun OR Name:Weapon))`  
* You can search for phrases in Comprehend results like this, `PhraseText:"some deep water" AND Confidence:>80`
* To see the full set of attributes that you can search for, click the Analytics menu item and search for "*" in the Discover tab of Kibana.

# DEVELOPER'S GUIDE:

## Running a Development Environment:

Here's how to run this project on an Amazon Linux Docker container:

### Start an Amazon Linux container
```
docker run -it amazonlinux
yum groupinstall "Development Tools" -y
```

### Install npm
```
cd /root
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

=> Profile not found. Tried ~/.bashrc, ~/.bash_profile, ~/.zshrc, and ~/.profile.
=> Create one of them and run this script again
   OR
=> Append the following lines to the correct file yourself:

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm


[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
. .nvm/nvm.sh
nvm install --latest-npm
```

### Download MIE 
```
git clone ssh://git.amazon.com/pkg/MediaInsightsEngine
```

### Install the packages in package.json
```
cd MediaInsightsEngine/webapp
npm install
```

### Define the following environment variables in `webapp/public/runtimeConfig.json`:
* ELASTICSEARCH_ENDPOINT
* WORKFLOW_API_ENDPOINT
* DATAPLANE_API_ENDPOINT
* DATAPLANE_BUCKET
* USER_POOL_ID
* USER_POOL_CLIENT_ID
* IDENTITY_POOL_ID
* AWS_REGION


### Run with hot-reload for development:
```
npm run serve
```

### Define CORS policy to allow uploads to DATAPLANE_BUCKET

Files will not upload through the MIE webapp until you add a CORS rule to the DATAPLANE_BUCKET for the IP address that the webapp is running on. If you run the webapp on localhost or from AWS CloudFront then add CORS rules like this:
```
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
<CORSRule>
    <AllowedOrigin>http://localhost:8080</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>POST</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
</CORSRule>
<CORSRule>
    <AllowedOrigin>https://d2xrlu7732gtkk.cloudfront.net</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>POST</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
</CORSRule>
</CORSConfiguration>
``` 

### Add your IP to Elasticsearch access policy
MIE provisions Elasticsearch with an IP-based access policy. If you open Kibana (e.g. `https://search-mie-es-....es.amazonaws.com/_plugin/kibana/`) and get the error, `{"Message":"User: anonymous is not authorized to perform: es:ESHttpGet"}`, then do this:
1. get the public IP address of your local computer at [http://checkip.amazonaws.com/](http://checkip.amazonaws.com/)
2. Add that IP address + "/32" to the Access Policy in your Elasticsearch cluster, then click Submit. 
3. Wait a few minutes for the Domain status to change from "Processing" to "Active", then try to open Kibana again.
  
## Running a Production Environment:

Here's how to run this front-end in a production environment on AWS:

### Deploy MIE back-end

Set required env vars, liks this:
```
MIE_STACK_NAME=mie123
DIST_OUTPUT_BUCKET=media-insights-engine
REGION=us-east-1
PROFILE=mie
VERSION=1.0.1
DATETIME=$(date '+%s')
DIST_OUTPUT_BUCKET=$DIST_OUTPUT_BUCKET-$DATETIME
```

Run the build script, like this:
```
cd .../MediaInsightsEngine/deployment
aws s3 mb s3://$DIST_OUTPUT_BUCKET-$REGION --region $REGION --profile $PROFILE
./build-s3-dist.sh $DIST_OUTPUT_BUCKET $VERSION $REGION $PROFILE
```
Then deploy the dist/media-insights-stack.template file with DeployDemoSite set to false, like this:
```
aws cloudformation create-stack --stack-name $MIE_STACK_NAME --template-body file://dist/media-insights-stack.template --region $REGION --parameters ParameterKey=DeployOperatorLibrary,ParameterValue=true ParameterKey=DeployRekognitionWorkflow,ParameterValue=true ParameterKey=DeployInstantTranslateWorkflow,ParameterValue=true ParameterKey=DeployTestWorkflow,ParameterValue=false ParameterKey=DeployAnalyticsPipeline,ParameterValue=true ParameterKey=DeployTranscribeWorkflow,ParameterValue=true ParameterKey=DeployDemoSite,ParameterValue=false --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --profile $PROFILE
``` 

### Set Vue.js Environment

Setup environment variables for API endpoints, like this:
```
DATAPLANE_BUCKET=$(aws cloudformation describe-stacks --stack-name $MIE_STACK_NAME --region $REGION --query 'Stacks[].Outputs[?OutputKey==`DataplaneBucket`].OutputValue' --output text --profile $PROFILE)
DATAPLANE_API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $MIE_STACK_NAME --region $REGION --query 'Stacks[].Outputs[?OutputKey==`DataplaneApiEndpoint`].OutputValue' --output text --profile $PROFILE)
WORKFLOW_API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $MIE_STACK_NAME --region $REGION --query 'Stacks[].Outputs[?OutputKey==`WorkflowApiEndpoint`].OutputValue' --output text --profile $PROFILE)
DATAPLANE_PATH=$DATAPLANE_BUCKET/private/media/
ELASTICSEARCH_DOMAINNAME=`aws es list-domain-names --query 'DomainNames[].DomainName' --output text --profile $PROFILE`
ELASTICSEARCH_ENDPOINT=`aws es describe-elasticsearch-domain --domain-name $ELASTICSEARCH_DOMAINNAME --query 'DomainStatus.Endpoint' --output text --profile $PROFILE`

echo -e "{\"ELASTICSEARCH_ENDPOINT\": \"https://$ELASTICSEARCH_ENDPOINT\", \"WORKFLOW_API_ENDPOINT\": \"$WORKFLOW_API_ENDPOINT\", \"DATAPLANE_API_ENDPOINT\": \"$DATAPLANE_ENDPOINT\", \"DATAPLANE_BUCKET\": \"$DATAPLANE_BUCKET\", \"USER_POOL_ID\": \"$USER_POOL_ID\", \"USER_POOL_CLIENT_ID\": \"$USER_POOL_CLIENT_ID\", \"IDENTITY_POOL_ID\": \"$IDENTITY_POOL_ID\", \"AWS_REGION\": \"$REGION\"}" >> ../webapp/public/runtimeConfig.json
```

### Setup S3 bucket
    * Create a public S3 bucket to host the website.
    * Enable static website hosting
    * On the S3 bucket, uncheck block public access and set the following bucket policy:
```
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "PublicReadGetObject",
          "Effect": "Allow",
          "Principal": "*",
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::mie-rodeo-demo01-website/*"
      }
  ]
}
```

### Setup proxy for Elasticsearch
* Create an EC2 Amazon Linux instance with open ports 22, 80, and 443.
* Install Nginx and Cloudfront, per this blog:
[https://w.amazon.com/bin/view/Elemental/TechnicalMarketing/kibana_reverse_proxy/](https://w.amazon.com/bin/view/Elemental/TechnicalMarketing/kibana_reverse_proxy/)

### Setup Cloudfront

You will need 2 Cloudfronts. One for elasticsearch, one for the s3 web url. 

***Sample Cloudfront settings for Elasticsearch:***

* Origin Domain Name: ec2-34-245-221-85.eu-west-1.compute.amazonaws.com
* Origin ID: Custom-ec2-34-245-221-85.eu-west-1.compute.amazonaws.com
* TLSv1 (default)
* HTTP Only
* Behaviors:
  * Viewer Protocol Policy: Redirect HTTP to HTTPS
  * Allowed HTTP Methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
  * Whitelist Headers:  <-- needed in order to avoid CORS errors
    * Access-Control-Request-Headers (custom)
    * Access-Control-Request-Method (custom)
    * Origin

***Sample Cloudfront settings for S3 web hosting bucket:***

* Origin Domain Name: mie-rodeo-demo01-website.s3-website-eu-west-1.amazonaws.com
* Origin ID: S3-Website-mie-rodeo-demo01-website.s3-website-eu-west-1.amazonaws.com
* Behaviors:
  * Viewer Protocol Policy: Redirect HTTP to HTTPS
  * Allowed HTTP Methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
  * Cache Based on Seleted Request Headers: All
  * Query String Forwarding and Caching: Forward all, cache based on all.  <-- because our Elastic queries use a "?" in the search url.
* Error Pages:
* Read more: [https://gist.github.com/bradwestfall/b5b0e450015dbc9b4e56e5f398df48ff#spa](https://gist.github.com/bradwestfall/b5b0e450015dbc9b4e56e5f398df48ff#spa)
* HTTP Error Code: 404
* TTL: 0
* Custom Error Response: Yes
* Response Page Path: /index.html
* HTTP Response Code: 200
* Set Max TTL on caching to 0 for both cloudfronts (default 31536000)
  
### Compile and Deploy site files to S3

```
cd ../webapp/
rm -rf dist/*
npm run build
npm run deploy
```

### Set CORS policy on the Dataplane bucket
Set CORS policy on the Dataplane bucket, like this:
```
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
<CORSRule>
 <AllowedOrigin>https://d85x32zms5ar1.cloudfront.net</AllowedOrigin>
 <AllowedMethod>GET</AllowedMethod>
 <AllowedMethod>POST</AllowedMethod>
 <AllowedHeader>*</AllowedHeader>
</CORSRule>
</CORSConfiguration>
```
