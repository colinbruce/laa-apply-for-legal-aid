require 'rails_helper'

module CFE
  RSpec.describe CreateCapitalsService do
    let!(:application) { create :legal_aid_application, :with_applicant, with_bank_accounts: 6 }
    let!(:other_assets_declaration) { my_other_asset_declaration }
    let!(:savings_amount) { my_savings_amount }
    let(:submission) { create :cfe_submission, aasm_state: 'applicant_created', legal_aid_application: application }
    let(:service) { described_class.new(submission) }
    let(:dummy_response) { dummy_response_hash.to_json }

    describe '#cfe_url' do
      it 'contains the submission assessment id' do
        expect(service.cfe_url)
          .to eq "#{Rails.configuration.x.check_financial_eligibility_host}/assessments/#{submission.assessment_id}/capitals"
      end
    end

    describe '#request payload' do
      it 'creates the expected payload from the values in the applicant' do
        response_hash = JSON.parse(service.request_body, symbolize_names: true)
        response_hash.each_key do |key|
          expect(response_hash[key]).to match_array(expected_payload_hash[key])
        end
      end
    end

    describe '.call' do
      around do |example|
        VCR.turn_off!
        example.run
        VCR.turn_on!
      end

      context 'successful post' do
        before { stub_request(:post, service.cfe_url).with(body: expected_payload_hash.to_json).to_return(body: dummy_response) }

        it 'updates the submission record from applicant_created to capitals_created' do
          expect(submission.aasm_state).to eq 'applicant_created'
          CreateCapitalsService.call(submission)
          expect(submission.aasm_state).to eq 'capitals_created'
        end

        it 'creates a submission_history record' do
          expect {
            CreateCapitalsService.call(submission)
          }.to change { submission.submission_histories.count }.by 1
          history = CFE::SubmissionHistory.last
          expect(history.submission_id).to eq submission.id
          expect(history.url).to eq service.cfe_url
          expect(history.http_method).to eq 'POST'
          expect(history.request_payload).to eq expected_payload_hash.to_json
          expect(history.http_response_status).to eq 200
          expect(history.response_payload).to eq dummy_response
          expect(history.error_message).to be_nil
        end
      end

      describe 'failed calls to CFE' do
        it_behaves_like 'a failed call to CFE'
      end
    end
    def my_other_asset_declaration
      create :other_assets_declaration,
             :with_all_values,
             legal_aid_application: application,
             inherited_assets_value: nil,
             money_owed_value: 0.0
    end

    def my_savings_amount
      create :savings_amount,
             :with_values,
             legal_aid_application: application,
             plc_shares: nil,
             peps_unit_trusts_capital_bonds_gov_stocks: 0.0,
             life_assurance_endowment_policy: nil
    end

    def expected_payload_hash # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      {
        bank_accounts: [
          {
            description: 'Current accounts',
            value: savings_amount.offline_current_accounts.to_s
          },
          {
            description: 'Savings accounts',
            value: savings_amount.offline_savings_accounts.to_s
          },
          {
            description: 'Money not in a bank account',
            value: savings_amount.cash.to_s
          },
          {
            description: "Access to another person's bank account",
            value: savings_amount.other_person_account.to_s
          },
          {
            description: 'ISAs, National Savings Certificates and Premium Bonds',
            value: savings_amount.national_savings.to_s
          },
          {
            description: 'Online current accounts',
            value: application.online_current_accounts_balance
          },
          {
            description: 'Online savings accounts',
            value: application.online_savings_accounts_balance
          }
        ],
        non_liquid_capital: [
          {
            description: 'Timeshare property',
            value: other_assets_declaration.timeshare_property_value.to_s
          },
          {
            description: 'Land',
            value: other_assets_declaration.land_value.to_s
          },
          {
            description: 'Any valuable items worth more than £500',
            value: other_assets_declaration.valuable_items_value.to_s
          },
          { description: 'Interest in a trust',
            value: other_assets_declaration.trust_value.to_s }
        ]
      }
    end

    def dummy_response_hash
      {
        "success": true
      }
    end
  end
end
