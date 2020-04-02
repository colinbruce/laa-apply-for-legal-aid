require 'rails_helper'

RSpec.describe StateBenefitAnalyserService do
  let(:legal_aid_application) { create :legal_aid_application }
  let(:applicant) { create :applicant, legal_aid_application: legal_aid_application, national_insurance_number: nino }
  let(:bank_provider) { create :bank_provider, applicant: applicant }
  let(:bank_account1) { create :bank_account, bank_provider: bank_provider }
  let(:nino) { 'YS327299B' }
  let!(:state_benefit_transaction_type) { create :transaction_type, :benefits }

  describe '.call' do
    before do
      allow(CFE::ObtainStateBenefitTypesService).to receive(:call).and_return(dummy_benefits)
    end

    subject { described_class.call(legal_aid_application) }

    context 'there are no state benefit transactions' do
      let!(:transactions) { create_mix_of_non_benefit_transactions }
      it 'does not change any bank transactions' do
        subject
        expect(legal_aid_application.reload.bank_transactions.order(:id)).to eq transactions
      end
    end

    context 'DWP payment for a different nino' do
      let!(:transactions) { [create(:bank_transaction, :credit, description: 'DWP YS327299X UC', bank_account: bank_account1)] }
      it 'does not mark the transaction as a state benefit' do
        subject
        expect(legal_aid_application.reload.bank_transactions).to eq transactions
      end
    end

    context 'DWP payment for this applicant with recognised code' do
      let!(:transactions) { [create(:bank_transaction, :credit, description: "DWP #{nino} DLA", bank_account: bank_account1)] }
      it 'marks the transaction as a state benefit' do
        subject
        tx = legal_aid_application.reload.bank_transactions.first
        expect(tx.transaction_type_id).to eq state_benefit_transaction_type.id
      end

      it 'updates the meta data with the label of the state benefit' do
        subject
        tx = legal_aid_application.reload.bank_transactions.first
        expect(tx.meta_data).to eq 'disability_living_allowance'
      end
    end

    context 'DWP payment for this applicant with unrecognised code' do
      let!(:transactions) { [create(:bank_transaction, :credit, description: "DWP #{nino} XXXX", bank_account: bank_account1)] }
      it 'marks the transaction as a state benefit' do
        subject
        tx = legal_aid_application.reload.bank_transactions.first
        expect(tx.transaction_type_id).to eq state_benefit_transaction_type.id
      end

      it 'updates the meta data with the label of the state benefit' do
        subject
        tx = legal_aid_application.reload.bank_transactions.first
        expect(tx.meta_data).to eq 'Unknown code XXXX'
      end
    end

    def dummy_benefits
      [
        { 'label' => 'cold_weather_payment', 'name' => 'Cold Weather Payment', 'dwp_code' => 'CWP' },
        { 'label' => 'disability_living_allowance', 'name' => 'Disability Living Allowance', 'dwp_code' => 'DLA' },
        { 'label' => 'employment_support_allowance', 'name' => 'Employment Support Allowance', 'dwp_code' => 'ESA' },
        { 'label' => 'social_fund_payments', 'name' => 'Social Fund Payment', 'dwp_code' => nil }
      ]
    end

    def create_mix_of_non_benefit_transactions
      transactions = create_list :bank_transaction, 3, bank_account: bank_account1
      transactions.sort_by(&:id)
    end
  end
end
