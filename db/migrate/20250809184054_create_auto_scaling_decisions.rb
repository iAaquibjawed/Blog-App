class CreateAutoScalingDecisions < ActiveRecord::Migration[7.0]
  def change
    create_table :auto_scaling_decisions do |t|
      t.json :metrics, null: false
      t.json :prediction, null: false
      t.string :action_taken, null: false
      t.float :confidence, null: false
      t.timestamp :timestamp, null: false
      t.boolean :execution_success, default: false
      t.boolean :aws_scaling_used, default: false

      t.timestamps
    end

    add_index :auto_scaling_decisions, :timestamp
    add_index :auto_scaling_decisions, :action_taken
  end
end