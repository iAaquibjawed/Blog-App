# require 'prometheus_exporter/middleware'
# require 'prometheus_exporter/instrumentation'

# Rails.application.middleware.unshift PrometheusExporter::Middleware
# PrometheusExporter::Instrumentation::Process.start(type: 'web')

# # Optionally add DB metrics
# PrometheusExporter::Instrumentation::ActiveRecord.start
