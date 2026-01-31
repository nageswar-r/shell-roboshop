#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0a7b91aa77cf9de83"
DOMAIN_NAME="sandh.co.in"
ZONE_ID="Z086001213PRS8PI96NCE"


for instance in $@   
do 
INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $instance == "frontend" ]; then
   IP=$(
    aws ec2 describe-instances  \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text
   )
   RECORD_NAME="$DOMAIN_NAME"
   else
    IP=$(
    aws ec2 describe-instances  \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[].Instances[].PrivateIpAddress' \
    --output text
   )
   RECORD_NAME="$instance.$DOMAIN_NAME"
   fi

echo "IP address: $IP"

aws route53 change-resource-record-sets \
--hosted-zone-id $ZONE_ID \
--change-batch '
{
"Comment": "Update A record for $instance",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
'

 echo "record updated for $instance"

done