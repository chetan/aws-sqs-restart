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

### Sample output

```
$ ./daemon.rb
Listening on SQS queue 'hang-restart-test' for alarm events...
-> received alarm at 2013-10-09 18:53:39 UTC
   alarm published at 2013-10-09 18:53:38 UTC
   reason: Threshold Crossed: 1 datapoint (100.0) was greater than or equal to the threshold (90.0).
   telling i-a1b2c3d4 to reboot
```
