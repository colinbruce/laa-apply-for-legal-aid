class CreateStateMachineProxies < ActiveRecord::Migration[6.0]
  def change
    create_table :state_machine_proxies do |t|
      t.integer :thing_id
      t.string :type
      t.string :aasm_state
    end
  end
end
