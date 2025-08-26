class AutoScalingDecision < ApplicationRecord
  validates :action_taken, presence: true, inclusion: { in: %w[scale_up scale_down maintain] }
  validates :confidence, presence: true, numericality: { in: 0.0..1.0 }
  validates :timestamp, presence: true

  scope :recent, -> { where('timestamp > ?', 24.hours.ago) }
  scope :by_action, ->(action) { where(action_taken: action) }

  def self.scaling_history(hours = 24)
    recent.where('timestamp > ?', hours.hours.ago).order(:timestamp)
  end
end