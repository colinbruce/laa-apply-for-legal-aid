require 'rails_helper'

RSpec.describe 'Firm' do
  let!(:passported_role) { create :role, :application_passported }
  let!(:non_passported_role) { create :role, :application_non_passported }
  let(:firm) { create :firm }

  describe '#roles' do
    context 'no roles' do
      it 'has no roles' do
        expect(firm.roles).to be_empty
      end
    end

    context 'has one role' do
      before { firm.roles << passported_role }
      it 'has the passported role' do
        expect(firm.reload.roles).to eq [ passported_role ]
      end
    end

    context 'has all roles' do
      before { Role.all.each { |r| firm.roles << r } }
      it 'has both roles' do
        expect(firm.reload.roles).to match_array [passported_role, non_passported_role]
      end
    end
  end
end
