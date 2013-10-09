# aws-sqs-restart
A simple daemon for restarting EC2 instances via CloudWatch alarms published
to SQS.

### Install

```
$ git clone https://github.com/chetan/aws-sqs-restart.git
$ cd aws-sqs-restart
$ bundle install
```

### Configure

You must export the following environment variables (or add them to the
command line):

 * AWS_ACCESS_KEY_ID
 * AWS_SECRET_ACCESS_KEY
 * AWS_QUEUE_NAME

### Run

```
$ ./daemon.rb
or
$ ./daemon.rb 2>&1 >restart.log &
```
