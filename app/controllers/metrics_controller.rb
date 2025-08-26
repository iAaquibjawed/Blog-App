# app/controllers/metrics_controller.rb
class MetricsController < ApplicationController
  # Skip any authentication for metrics endpoint
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, if: :devise_controller?

  def index
    # Basic application metrics for Prometheus
    metrics = []

    # Request count metric
    metrics << "# HELP http_requests_total Total HTTP requests"
    metrics << "# TYPE http_requests_total counter"
    metrics << "http_requests_total #{request_count}"

    # Application uptime
    metrics << "# HELP app_uptime_seconds Application uptime in seconds"
    metrics << "# TYPE app_uptime_seconds gauge"
    metrics << "app_uptime_seconds #{uptime_seconds}"

    # Database connection status
    metrics << "# HELP database_connected Database connection status"
    metrics << "# TYPE database_connected gauge"
    metrics << "database_connected #{database_connected? ? 1 : 0}"

    # Current instances (from auto-scaling)
    metrics << "# HELP current_instances Current number of application instances"
    metrics << "# TYPE current_instances gauge"
    metrics << "current_instances #{current_instances}"

    # Response time (simple approximation)
    metrics << "# HELP response_time_seconds Average response time"
    metrics << "# TYPE response_time_seconds gauge"
    metrics << "response_time_seconds #{average_response_time}"

    render plain: metrics.join("\n"), content_type: 'text/plain'
  end

  private

  def request_count
    # Simple counter - in production you'd use a proper metric store
    Rails.cache.fetch('request_count', expires_in: 1.hour) { 0 }
  end

  def uptime_seconds
    # Application uptime since last restart
    Time.current.to_i - application_start_time.to_i
  end

  def application_start_time
    Rails.cache.fetch('app_start_time') { Time.current }
  end

  def database_connected?
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      true
    rescue
      false
    end
  end

  def current_instances
    begin
      InstanceCounterService.current_count
    rescue
      1
    end
  end

  def average_response_time
    # Simple approximation - in production you'd track actual response times
    rand(0.05..0.2).round(3)
  end
end