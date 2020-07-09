require 'rails_helper'

RSpec.describe Provider, type: :model do
  let!(:passported_role) { create :role, :application_passported }
  let!(:non_passported_role) { create :role, :application_non_passported }
  let(:firm) { create :firm }
  let(:provider) { create :provider, firm: firm }

  describe '#update_details' do
    context 'firm exists' do
      it 'does not call provider details creator immediately' do
        expect(ProviderDetailsCreator).not_to receive(:call).with(provider)
        provider.update_details
      end

      it 'schedules a background job' do
        expect(ProviderDetailsCreatorWorker).to receive(:perform_async).with(provider.id)
        provider.update_details
      end
    end

    context 'firm does not exist' do
      let(:firm) { nil }

      it 'updates provider details immediately' do
        expect(ProviderDetailsCreator).to receive(:call).with(provider)
        provider.update_details
      end
    end
  end

  describe '#whitelisted_user?' do
    before do
      allow(HostEnv).to receive(:production?).and_return(true)
      Rails.configuration.x.application.whitelisted_users = %w[user1 user2 user3]
    end

    context 'user is whitelisted' do
      context 'provider username is in lower case' do
        let(:provider) { create :provider, username: Rails.configuration.x.application.whitelisted_users.sample.downcase }
        it 'returns true' do
          expect(provider.whitelisted_user?).to be true
        end
      end
      context 'provider username is in upper case' do
        let(:provider) { create :provider, username: Rails.configuration.x.application.whitelisted_users.sample.upcase }
        it 'returns true' do
          expect(provider.whitelisted_user?).to be true
        end
      end
    end
    context 'user is not whitelisted' do
      it 'returns false' do
        expect(provider.whitelisted_user?).to be false
      end
    end
  end

  describe '#roles' do
    context 'no roles' do
      it 'has no roles' do
        expect(provider.roles).to be_empty
      end
    end

    context 'has one role' do
      before { provider.roles << passported_role }
      it 'has the passported role' do
        expect(provider.reload.roles).to eq [ passported_role ]
      end
    end

    context 'has all roles' do
      before { Role.all.each { |r| provider.roles << r } }
      it 'has both roles' do
        expect(provider.reload.roles).to match_array [passported_role, non_passported_role]
      end
    end
  end

  describe '#user_roles' do
    context 'no provider roles' do
      context 'no firm roles' do
        it 'is empty' do
          expect(provider.user_roles).to be_empty
        end
      end
      context 'firm roles exist' do
        before { provider.firm.roles << passported_role }
        it 'returns the firm roles' do
          expect(provider.user_roles).to eq [passported_role]
        end
      end
    end

    context 'provider_roles exist' do
      before do
        provider.firm.roles << passported_role
        provider.firm.roles << non_passported_role
        provider.roles << non_passported_role
      end
      it 'returns provider roles and ignores firm roles' do
        expect(provider.roles).to eq [non_passported_role]
      end
    end
  end

  context 'normalization of roles' do
    context 'provider roles are the same as firm roles' do
      before do
        provider.roles << [passported_role, non_passported_role]
        provider.firm.roles << [passported_role, non_passported_role]
      end
      it 'deletes the provider roles after save' do
        provider.save
      end
    end

    context 'provider roles are not the same as firm roles' do
      it 'does not delete provider roles after save'
    end
  end
end
