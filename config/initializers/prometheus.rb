# # config/initializers/prometheus.rb
# if Rails.env.production? && ENV['SKIP_PROMETHEUS'] == 'true'
#   # Skip prometheus setup during asset precompilation
#   Rails.logger.info "Skipping Prometheus setup"
# else
#   # Your existing prometheus configuration here
# end