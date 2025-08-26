class MetricsCollectorService
  include HTTParty

  def initialize
    @prometheus_url = Rails.application.config.autoscaling.prometheus_url
    @metrics_window = Rails.application.config.autoscaling.metrics_window
  end

  def collect_current_metrics
    metrics = {}

    begin
      # Collect CPU metrics
      cpu_query = "avg(rate(container_cpu_usage_seconds_total[#{@metrics_window}])) * 100"
      metrics[:cpu_usage] = query_prometheus(cpu_query) || 0.0

      # Collect Memory metrics
      memory_query = "avg(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100"
      metrics[:memory_usage] = query_prometheus(memory_query) || 0.0

      # Collect Request metrics
      request_query = "sum(rate(http_requests_total[#{@metrics_window}]))"
      metrics[:requests_per_second] = query_prometheus(request_query) || 0.0

      # Collect Response time metrics
      response_time_query = "avg(http_request_duration_seconds_sum / http_request_duration_seconds_count) * 1000"
      metrics[:response_time_ms] = query_prometheus(response_time_query) || 0.0

      # Collect Network metrics
      network_in_query = "sum(rate(container_network_receive_bytes_total[#{@metrics_window}])) / 1024 / 1024"
      metrics[:network_in_mbps] = query_prometheus(network_in_query) || 0.0

      network_out_query = "sum(rate(container_network_transmit_bytes_total[#{@metrics_window}])) / 1024 / 1024"
      metrics[:network_out_mbps] = query_prometheus(network_out_query) || 0.0

      # Add current time-based features
      current_time = Time.current
      metrics[:hour] = current_time.hour
      metrics[:day_of_week] = current_time.wday
      metrics[:is_weekend] = current_time.saturday? || current_time.sunday?
      metrics[:is_business_hours] = (9..17).include?(current_time.hour)

      # Application-specific metrics
      metrics[:app_id] = 1 # Your blog app ID
      metrics[:app_type] = 'web'
      metrics[:queue_length] = get_queue_length
      metrics[:active_connections] = get_active_connections

      # Current infrastructure details
      metrics[:allocated_cpu_cores] = get_allocated_cpu_cores
      metrics[:allocated_memory_gb] = get_allocated_memory_gb
      metrics[:current_instances] = get_current_instances

      # Historical averages (simplified - you may want to store these in Redis)
      metrics[:cpu_usage_1h_avg] = get_historical_average(:cpu_usage, 1.hour)
      metrics[:cpu_usage_4h_avg] = get_historical_average(:cpu_usage, 4.hours)
      metrics[:cpu_usage_24h_avg] = get_historical_average(:cpu_usage, 24.hours)
      metrics[:memory_usage_1h_avg] = get_historical_average(:memory_usage, 1.hour)
      metrics[:requests_1h_avg] = get_historical_average(:requests_per_second, 1.hour)

      # Disk I/O approximation
      metrics[:disk_io_iops] = (metrics[:requests_per_second] * 0.1).round(2)

      Rails.logger.info "Collected metrics: #{metrics}"
      metrics

    rescue StandardError => e
      Rails.logger.error "Failed to collect metrics: #{e.message}"
      default_metrics
    end
  end

  private

  def query_prometheus(query)
    response = HTTParty.get("#{@prometheus_url}/api/v1/query", {
      query: { query: query },
      timeout: 10
    })

    if response.success? && response.parsed_response['status'] == 'success'
      data = response.parsed_response['data']['result']
      return data.first&.dig('value', 1)&.to_f if data.any?
    end

    nil
  rescue StandardError => e
    Rails.logger.error "Prometheus query failed: #{e.message}"
    nil
  end

  def get_queue_length
    # Integrate with your queue system (Sidekiq, etc.)
    Sidekiq::Queue.new.size rescue 0
  end

  def get_active_connections
    # This could be from Nginx metrics or application server metrics
    # For now, estimate based on requests per second
    # (collect_current_metrics[:requests_per_second] * 0.1).to_i rescue 10
    10
  end

  def get_allocated_cpu_cores
    # Get from container/instance configuration
    ENV.fetch('ALLOCATED_CPU_CORES', '2').to_i
  end

  def get_allocated_memory_gb
    # Get from container/instance configuration
    ENV.fetch('ALLOCATED_MEMORY_GB', '4').to_i
  end

  def get_current_instances
    # This should integrate with your container orchestration system
    # For AWS EC2, you could use AWS SDK
    # For now, return a default value
    AutoScalingService.current_instance_count
  end

#   def get_historical_average(metric, time_period)
#     # Simplified - in production, you'd query historical data from Redis/database
#     # For now, return current value with some noise
#     # current_value = collect_current_metrics[metric] || 0.0
#     # current_value * (0.8 + rand * 0.4) # ±20% variation
#       current_value = collect_current_metrics[metric] || 0.0  # ❌ This calls itself
#       current_value * (0.8 + rand * 0.4)
#   end

    def get_historical_average(metric, time_period)
    # Return default values to avoid circular calls
    case metric
    when :cpu_usage then 0.3
    when :memory_usage then 0.3
    when :requests_per_second then 10.0
    else 0.0
    end
    end

  def default_metrics
    {
      cpu_usage: 0.3,
      memory_usage: 0.3,
      requests_per_second: 10.0,
      response_time_ms: 100.0,
      network_in_mbps: 1.0,
      network_out_mbps: 1.0,
      hour: Time.current.hour,
      day_of_week: Time.current.wday,
      is_weekend: Time.current.saturday? || Time.current.sunday?,
      is_business_hours: (9..17).include?(Time.current.hour),
      app_id: 1,
      app_type: 'web',
      queue_length: 0,
      active_connections: 10,
      allocated_cpu_cores: 2,
      allocated_memory_gb: 4,
      current_instances: 1,
      cpu_usage_1h_avg: 0.3,
      cpu_usage_4h_avg: 0.3,
      cpu_usage_24h_avg: 0.3,
      memory_usage_1h_avg: 0.3,
      requests_1h_avg: 10.0,
      disk_io_iops: 1.0
    }
  end
end