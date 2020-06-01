class Thing < ApplicationRecord

  attr_reader :state_machine

  after_initialize :initialize_state_machine

  delegate :state, to: :state_machine

  def provider_setup!
    @state_machine.provider_setup!
  end


  def initialize_state_machine
    self.state_machine_klass = 'PassportedStateMachine' unless self.state_machine_klass.present?
    self.saved_state = 'initiated' unless self.saved_state.present?
    @state_machine = state_machine_klass.constantize.new(self)
    @state_machine.aasm_write_state self.saved_state.to_sym
  end
end
