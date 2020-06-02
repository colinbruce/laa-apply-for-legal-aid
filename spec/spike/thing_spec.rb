require 'rails_helper'

RSpec.describe Thing do

  context 'initailizeing a new object' do
    it 'instantiates the default state machine' do
      t = Thing.new(name: 'John' )
      expect(t.state).to eq 'initiated'
    end
  end
  
  
  context 'advancing state' do
    let(:thing) { Thing.create(name: 'Mike' ) }
    it 'saves advances state and saves' do
      thing.provider_setup!
      expect(thing.state).to eq 'provider_setup'
    end
  end

  context 'loading an existing record and advancing state' do
    let(:thing) do
      t = Thing.new
      t.provider_setup!
      t
    end

    it 'is in the expected state and can be advanced' do
      expect(thing.state).to eq 'provider_setup'
      thing.provider_entering_means!
      expect(thing.state).to eq 'provider_entering_means'
    end
  end

  context 'switching state machines' do
    let(:thing) do
      t = Thing.new
      t.provider_setup!
      t
    end

    it 'switches to the new state machine' do
      expect(thing.state_machine).to be_instance_of(PassportedStateMachine)
      thing.switch_state_machines
      expect(thing.state_machine).to be_instance_of(NonPassportedStateMachine)
      thing.citizen_entering_means!
      expect(thing.state).to eq 'citizen_entering_means'
    end

  end
end
