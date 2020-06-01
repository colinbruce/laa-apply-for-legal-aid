require 'rails_helper'

RSpec.describe Thing do
let(:laa) { create :legal_aid_application }

  context 'initializing a new object' do
    it 'sets the state machine to the default state machine' do
      thing = Thing.new
      expect(thing.state_machine_klass).to eq 'PassportedStateMachine'
    end

    it 'instantiates a state machine' do
      thing = Thing.new
      expect(thing.state_machine).to be_instance_of(PassportedStateMachine)
    end
  end

  context 'advancing state' do
    let(:thing) { Thing.new }
    it 'advances' do
      expect(thing.state).to eq :initiated
      thing.provider_setup!
      expect(thing.state).to eq :provider_setup
    end
  end

  context 'saving a record' do
    let(:thing) do
      Thing.create(state_machine_klass: 'PassportedStateMachine', saved_state: 'initiated', name: 'John Doe')
    end

    it 'saves the new state' do
      thing.provider_setup!
      thing.save!
      thing2 = Thing.find(thing.id)
      expect(thing2.saved_state).to eq 'provider_setup'
      expect(thing2.state_machine_klass).to eq 'PassportedStateMachine'
      expect(thing2.state).to eq :provider_setup
    end
  end
end
