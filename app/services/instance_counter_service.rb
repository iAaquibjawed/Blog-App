class InstanceCounterService
  def self.current_count
    if aws_scaling_enabled?
      AwsScalingService.new.current_instance_count
    else
      # Use Redis for local development (properly accessed)
      redis_client&.get('current_instances')&.to_i || 1
    end
  end

  def self.update_count(count)
    return if aws_scaling_enabled? # Don't update if using AWS

    redis_client&.set('current_instances', count)
  end

  private

  def self.aws_scaling_enabled?
    ENV.fetch('USE_AWS_SCALING', 'false') == 'true'
  end

  def self.redis_client
    # ✅ Use proper Redis connection instead of global variable
    @redis_client ||= if defined?(Redis)
                        Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
                      end
  rescue Redis::CannotConnectError => e
    Rails.logger.warn "Redis connection failed: #{e.message}"
    nil
  end
end