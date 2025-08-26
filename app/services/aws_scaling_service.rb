# app/services/auto_scaling_service.rb
# ✅ Fixed: Main orchestrator service with proper conventions
class AutoScalingService
  def initialize
    @metrics_collector = MetricsCollectorService.new
    @ml_predictor = MlPredictionService.new
    @aws_scaler = AwsScalingService.new if aws_scaling_enabled?
  end

  def evaluate_and_scale
    return unless Rails.application.config.autoscaling.enabled

    begin
      # Collect current metrics
      metrics = @metrics_collector.collect_current_metrics

      # Enhance metrics with AWS data if available
      if aws_scaling_enabled? && @aws_scaler
        aws_metrics = @aws_scaler.get_instance_metrics
        metrics.merge!(aws_metrics[:aggregate]) if aws_metrics[:aggregate]
      end

      # Get ML prediction
      prediction = @ml_predictor.predict_scaling_action(metrics)

      # Log the decision
      decision = AutoScalingDecision.create!(
        metrics: metrics,
        prediction: prediction,
        action_taken: prediction[:action],
        confidence: prediction[:confidence],
        timestamp: Time.current,
        aws_scaling_used: aws_scaling_enabled?
      )

      # Execute scaling action
      success = execute_scaling_action(prediction[:action], prediction[:confidence])

      # Update decision record with result
      decision.update!(execution_success: success)

      Rails.logger.info "Auto-scaling evaluation completed: #{prediction[:action]} (confidence: #{prediction[:confidence]}, success: #{success})"

    rescue StandardError => e
      Rails.logger.error "Auto-scaling evaluation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  private

  def execute_scaling_action(action, confidence)
    # Only act if confidence is above threshold
    return true if confidence < 0.7

    current_instances = InstanceCounterService.current_count

    case action
    when 'scale_up'
      scale_up(current_instances)
    when 'scale_down'
      scale_down(current_instances)
    when 'maintain'
      Rails.logger.info "Maintaining current instance count: #{current_instances}"
      true
    else
      false
    end
  end

  def scale_up(current_instances)
    max_instances = ENV.fetch('MAX_INSTANCES', '10').to_i
    return true if current_instances >= max_instances

    new_instances = [current_instances + 1, max_instances].min

    Rails.logger.info "Scaling UP: #{current_instances} -> #{new_instances}"

    if aws_scaling_enabled? && @aws_scaler
      success = @aws_scaler.scale_to(new_instances)
      send_scaling_notification('scale_up', current_instances, new_instances) if success
      success
    else
      simulate_scale_up(new_instances)
      InstanceCounterService.update_count(new_instances)
      true
    end
  end

  def scale_down(current_instances)
    min_instances = ENV.fetch('MIN_INSTANCES', '1').to_i
    return true if current_instances <= min_instances

    new_instances = [current_instances - 1, min_instances].max

    Rails.logger.info "Scaling DOWN: #{current_instances} -> #{new_instances}"

    if aws_scaling_enabled? && @aws_scaler
      success = @aws_scaler.scale_to(new_instances)
      send_scaling_notification('scale_down', current_instances, new_instances) if success
      success
    else
      simulate_scale_down(new_instances)
      InstanceCounterService.update_count(new_instances)
      true
    end
  end

  def simulate_scale_up(new_instances)
    Rails.logger.info "🚀 Simulating scale up to #{new_instances} instances"
  end

  def simulate_scale_down(new_instances)
    Rails.logger.info "📉 Simulating scale down to #{new_instances} instances"
  end

  def send_scaling_notification(action, old_count, new_count)
    message = "Auto-scaling #{action}: #{old_count} -> #{new_count} instances"
    Rails.logger.info "📢 #{message}"

    # You could integrate with Slack, SNS, etc. here
    # SlackNotificationService.new.send_message(message)
    # SnsNotificationService.new.publish(message)
  end

  def aws_scaling_enabled?
    ENV.fetch('USE_AWS_SCALING', 'false') == 'true'
  end
end