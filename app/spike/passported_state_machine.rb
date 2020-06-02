class PassportedStateMachine < BaseStateMachine


  aasm do
    state :initiated, initial: true
    state :provider_setup
    state :provider_entering_means
    state :provider_entering_merits
    state :completed

    event :provider_setup do
      transitions from: :initiated, to: :provider_setup
    end

    event :provider_entering_means do
      transitions from: :provider_setup, to: :provider_entering_means
    end

    event :provider_entering_merits do
      transitions from: :provider_entering_means, to: :provider_entering_merits
    end

    event :complete do
      transitions from: :provider_entering_merits, to: :completed
    end
  end

end
