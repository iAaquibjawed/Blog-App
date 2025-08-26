class Admin::AutoScalingController < ApplicationController
  before_action :authenticate_admin! # Implement your admin authentication

  def index
    @current_instances = AutoScalingService.current_instance_count
    @recent_decisions = AutoScalingDecision.recent.order(timestamp: :desc).limit(20)
    @scaling_enabled = Rails.application.config.autoscaling.enabled
  end

  def metrics
    @metrics = MetricsCollectorService.new.collect_current_metrics
    render json: @metrics
  end

  def predict
    metrics = MetricsCollectorService.new.collect_current_metrics
    prediction = MlPredictionService.new.predict_scaling_action(metrics)
    render json: { metrics: metrics, prediction: prediction }
  end

  def toggle
    current_state = Rails.application.config.autoscaling.enabled
    Rails.application.config.autoscaling.enabled = !current_state

    redirect_to admin_auto_scaling_index_path,
      notice: "Auto-scaling #{Rails.application.config.autoscaling.enabled ? 'enabled' : 'disabled'}"
  end

  def force_evaluation
    AutoScalingJob.perform_later
    redirect_to admin_auto_scaling_index_path, notice: "Auto-scaling evaluation triggered"
  end
end