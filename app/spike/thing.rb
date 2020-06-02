class Thing < ApplicationRecord

  attr_reader :state_machine_proxy

  delegate :provider_setup!,
           :provider_entering_means!,
           :citizen_entering_means!,
           to: :state_machine_proxy

  has_one :state_machine, class_name: 'BaseStateMachine'

  def state
    state_machine_proxy.aasm_state
  end

  def state_machine_proxy
    if state_machine.nil?
      self.save!
      create_state_machine(type: 'PassportedStateMachine')
    end
    state_machine
  end

  def switch_state_machines
    save!
    state_machine.update!(type: 'NonPassportedStateMachine')
    reload
  end


end
