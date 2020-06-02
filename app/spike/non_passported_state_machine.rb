class NonPassportedStateMachine < BaseStateMachine


  aasm do
    state :provider_setup, initial: true
    state :citizen_entering_means
    state :provider_checking_means
    state :completed

    event :citizen_entering_means do
      transitions from: :provider_setup, to: :citizen_entering_means
    end

    event :provider_checking_means do
      transitions from: :citizen_entering_means, to: :provider_checking_means
    end

    event :complete do
      transitions from: :provider_checking_means, to: :completed
    end
  end

end
