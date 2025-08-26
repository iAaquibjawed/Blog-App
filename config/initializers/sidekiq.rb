if defined?(Sidekiq)
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }

    # Start auto-scaling job
    config.on(:startup) do
      Sidekiq.schedule = {
        'auto_scaling_evaluation' => {
          'every' => '1m',
          'class' => 'AutoScalingJob'
        }
      }

      Sidekiq::Scheduler.reload_schedule!
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
  end
end