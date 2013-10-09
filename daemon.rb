#!/usr/bin/env ruby

AWS_ACCESS_KEY = ENV["AWS_ACCESS_KEY_ID"]
AWS_SECRET_KEY = ENV["AWS_SECRET_ACCESS_KEY"]
AWS_QUEUE_NAME = ENV["AWS_QUEUE_NAME"]
AWS_TOPIC_NAME = ENV["AWS_TOPIC_ARN"]

require "aws-sdk"
require "multi_json"


def restart_instance(instance_id)

  inst = AWS::EC2.new.instances[instance_id]
  if !inst.exists? then
    return false
  end

  inst.reboot
  return true
end

def find_instance_id(dimensions)
  dimensions.each do |dim|
    if dim["name"] == "InstanceId" then
      return dim["value"]
    end
  end
  nil
end

def send_alert(log)
  return if AWS_TOPIC_NAME.nil? or AWS_TOPIC_NAME.empty?

  topic = AWS::SNS.new.topics[AWS_TOPIC_NAME]
  if topic.nil? then
    STDERR.puts "topic '#{AWS_TOPIC_NAME}' doesn't exist!"
    return
  end

  topic.publish(log, :subject => "[aws-sqs-restart] instance restarted")
  puts "   sent notification to #{AWS_TOPIC_NAME}"
end

################################################################################
# validate config
err = false
if !AWS_ACCESS_KEY or AWS_ACCESS_KEY.empty? then
   STDERR.puts "ERROR: missing required ENV variable 'AWS_ACCESS_KEY_ID'"
   err = true
end
if !AWS_SECRET_KEY or AWS_SECRET_KEY.empty? then
   STDERR.puts "ERROR: missing required ENV variable 'AWS_SECRET_ACCESS_KEY'"
   err = true
end
if !AWS_QUEUE_NAME or AWS_QUEUE_NAME.empty? then
   STDERR.puts "ERROR: missing required ENV variable 'AWS_QUEUE_NAME'"
   err = true
end
exit 1 if err


################################################################################
# main
$0 = "aws-sqs-restart-daemon [queue=#{AWS_QUEUE_NAME}]"
AWS.config(
  :access_key_id => AWS_ACCESS_KEY,
  :secret_access_key => AWS_SECRET_KEY)

puts "Listening on SQS queue '#{AWS_QUEUE_NAME}' for alarm events..."
begin
  AWS::SQS.new.queues.named(AWS_QUEUE_NAME).poll do |msg|

    log = []

    log << "-> received alarm at #{Time.new.gmtime}"
    sns = msg.as_sns_message
    log << "   alarm published at #{sns.published_at}"

    alarm = MultiJson.load(sns.body)
    log << "   reason: " + alarm["NewStateReason"]

    instance_id = find_instance_id(alarm["Trigger"]["Dimensions"])
    if !instance_id.nil? then
      if restart_instance(instance_id) then
        log << "   told #{instance_id} to reboot"
      else
        log << "   instance #{instance_id} doesn't exist!"
      end

    else
      log << "   got alarm with no instance id:"
      log << msg.body
    end

    out = log.join("\n")
    puts out
    if AWS_TOPIC_NAME then
      send_alert(out)
    end

    true
  end
rescue Interrupt => ex
end


# cloudwatch alarm message format:

# {
#     "AlarmName": "awsec2-hang-restart-testing-i-a7f950df-High-CPU-Utilization",
#     "AlarmDescription": "Created from EC2 Console",
#     "AWSAccountId": "221645429527",
#     "NewStateValue": "ALARM",
#     "NewStateReason": "Threshold Crossed: 1 datapoint (100.0) was greater than or equal to the threshold (90.0).",
#     "StateChangeTime": "2013-10-09T18:04:38.882+0000",
#     "Region": "US - N. Virginia",
#     "OldStateValue": "OK",
#     "Trigger": {
#         "MetricName": "CPUUtilization",
#         "Namespace": "AWS/EC2",
#         "Statistic": "AVERAGE",
#         "Unit": null,
#         "Dimensions": [{
#             "name": "InstanceId",
#             "value": "i-a7f950df"
#         }],
#         "Period": 60,
#         "EvaluationPeriods": 1,
#         "ComparisonOperator": "GreaterThanOrEqualToThreshold",
#         "Threshold": 90.0
#     }
# }
