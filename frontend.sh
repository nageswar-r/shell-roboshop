#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/robo-shell"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p /var/log/robo-shell

if [ $USER_ID -ne 0 ]; then
echo -e "$R Please run this script with root user $N" | tee -a $LOGS_FILE
exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
    echo -e "$2 .... $G Failed $N" | tee -a $LOGS_FILE
    exit 1
    else 
    echo -e "$2 .... $R Suceess $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nginx -y &>>$LOGS_FILE
validate $? "NGINX disable is"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
validate $? "NGINX 1.24 enable is"

dnf install nginx -y &>>$LOGS_FILE
validate $? "NGINX Installation is" 

systemctl enable nginx &>>$LOGS_FILE
systemctl start nginx &>>$LOGS_FILE
validate $? "NGINX service start is"  

rm -rf /usr/share/nginx/html/* 
validate $? "Remove data is"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "Data copy to /tmp is"

cd /usr/share/nginx/html
validate $? "Change directory is"
unzip /tmp/frontend.zip
validate $? "Unzip is"
cp $SCRIPT_DIR/frontend.txt /etc/nginx/nginx.conf
validate $? "Nginx content addition at boot of nginx.conf file is"

systemctl restart nginx &>>$LOGS_FILE
validate $? "Nginx service restart is"

