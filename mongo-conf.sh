#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/robo-shell"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

cp $pwd/mongod.repo /etc/yum.repos/

validate $? "Copying Mongo repo"

dnf install mongodb-org -y &>>$LOGS_FILE
validate $? "Installing MongoDB server"

systemctl enable mongod
validate $? "Enabling MongoDB"

systemctl start mongod
validate $? "Start MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "Allowing remote connections"

systemctl reload mongod
validate $? "Restarted Mongodb"