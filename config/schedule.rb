every 1.minute do
  runner "AutoScalingJob.perform_later"
end