class AutoScalingJob < ApplicationJob
  queue_as :default

  def perform
    AutoScalingService.new.evaluate_and_scale
  rescue StandardError => e
    Rails.logger.error "AutoScalingJob failed: #{e.message}"
    raise e
  end
end