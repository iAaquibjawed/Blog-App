class MlPredictionService
  include HTTParty

  def initialize
    @prediction_service_url = Rails.application.config.autoscaling.prediction_service_url
  end

  def predict_scaling_action(metrics)
    begin
      response = HTTParty.post("#{@prediction_service_url}/predict_simple", {
        body: metrics.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 10
      })

      if response.success?
        prediction = response.parsed_response
        Rails.logger.info "ML Prediction: #{prediction}"

        {
          action: prediction['action'],
          confidence: prediction['confidence'],
          probabilities: prediction['probabilities'],
          timestamp: prediction['timestamp'],
          success: true
        }
      else
        Rails.logger.error "ML prediction service returned error: #{response.code}"
        fallback_prediction(metrics)
      end

    rescue StandardError => e
      Rails.logger.error "Failed to get ML prediction: #{e.message}"
      fallback_prediction(metrics)
    end
  end

  private

  def fallback_prediction(metrics)
    # Simple rule-based fallback when ML service is unavailable
    action = if (metrics[:cpu_usage] || 0) > 80 || (metrics[:memory_usage] || 0) > 85 || (metrics[:response_time_ms] || 0) > 500
           'scale_up'
         elsif (metrics[:cpu_usage] || 0) < 20 && (metrics[:memory_usage] || 0) < 30 && (metrics[:current_instances] || 1) > 1
           'scale_down'
         else
           'maintain'
         end

    {
      action: action,
      confidence: 0.6, # Lower confidence for rule-based prediction
      probabilities: { action => 0.6, 'maintain' => 0.4 },
      timestamp: Time.current.iso8601,
      success: false,
      fallback: true
    }
  end
end