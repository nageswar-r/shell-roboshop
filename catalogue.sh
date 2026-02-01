#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/robo-shell"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.sandh.co.in

if [ $USER_ID -ne 0 ]; then

echo -e "$R Please run this script with root user $N" | tee -a $LOGS_FILE
exit 1
fi

mkdir -p /var/log/robo-shell

validate(){
    if [ $1 -ne 0 ]; then
    echo -e "$2 ....$R FAILURE $N" | tee -a $LOGS_FILE
    else
    echo -e "$2 ....$R SUCCESS $N" | tee -a $LOGS_FILE
    fi
}
dnf module disable nodejs -y &>>$LOGS_FILE
validate $? "Disabling node js" 
dnf module enable nodejs:20 -y &>>$LOGS_FILE
validate $? "Enabling nodejs 20"

dnf install nodejs -y &>>$LOGS_FILE
validate $? "Installing nodejs 20"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE

validate $? "roboshop user creation"
else 
    echo -e "Roboshop user already exists ...$Y SKIPPING $N"
fi

mkdir /app
validate $? "Creating app directroy"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOGS_FILE
validate $? "Downloading catalogue code"

cd /app
validate $? "Moving to app directory"

rm -rf /app/*
validate $? "Remoing existing data under /app"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
validate $? "Unzipping the code files to  /app"

npm install &>>$LOGS_FILE
validate $? "Installing the code files"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Catalogue service file copy" 

systemctl daemon-reload
systemctl enable catalogue  &>>$LOGS_FILE
systemctl start catalogue
validate $? "Starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOGS_FILE

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')


if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    validate $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
validate $? "Restarting catalogue"


