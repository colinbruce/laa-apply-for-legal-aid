require 'rails_helper'

module CFE # rubocop:disable Metrics/ModuleLength
  RSpec.describe ObtainAssessmentResultService do
    around do |example|
      VCR.turn_off!
      example.run
      VCR.turn_on!
    end

    let(:application) { create :legal_aid_application, application_ref: 'L-XYZ-999' }
    let(:submission) { create :cfe_submission, aasm_state: 'properties_created', legal_aid_application: application }
    let(:expected_response) { expected_response_hash.to_json }
    let(:service) { described_class.new(submission) }

    describe '#cfe_url' do
      it 'contains the submission assessment id' do
        expect(service.cfe_url)
          .to eq "#{Rails.configuration.x.check_finanical_eligibility_host}/assessments/#{submission.assessment_id}"
      end
    end

    context 'success' do
      before do
        stub_request(:get, service.cfe_url)
          .to_return(body: expected_response)
      end

      it 'calls the expected URL' do
        ObtainAssessmentResultService.call(submission)
      end

      it 'updates the submission state to results_obtained' do
        ObtainAssessmentResultService.call(submission)
        expect(submission.aasm_state).to eq 'results_obtained'
      end

      it 'stores the response in the submission cfe_result field' do
        ObtainAssessmentResultService.call(submission)
        expect(submission.cfe_result).to eq expected_response
      end

      it 'writes a history record' do
        ObtainAssessmentResultService.call(submission)
        history = submission.submission_histories.first
        expect(history.url).to eq service.cfe_url
        expect(history.http_method).to eq 'GET'
        expect(history.request_payload).to be_nil
        expect(history.http_response_status).to eq 200
        expect(history.response_payload).to eq expected_response
        expect(history.error_message).to be_nil
        expect(history.error_backtrace).to be_nil
      end
    end

    context 'unssuccessful call' do
      context 'http status 404' do
        before do
          stub_request(:get, service.cfe_url)
            .to_return(body: '', status: 404)
        end

        it 'updates the submission state to failed' do
          expect {
            ObtainAssessmentResultService.call(submission)
          }.to raise_error CFE::SubmissionError
          expect(submission.aasm_state).to eq 'failed'
        end

        it 'writes the details to the history record' do
          expect {
            ObtainAssessmentResultService.call(submission)
          }.to raise_error CFE::SubmissionError
          history = submission.submission_histories.last
          expect(history.url).to eq service.cfe_url
          expect(history.http_method).to eq 'GET'
          expect(history.request_payload).to be_nil
          expect(history.http_response_status).to eq 404
          expect(history.response_payload).to be_nil
          expect(history.error_message).to eq 'CFE::ObtainAssessmentResultService received CFE::SubmissionError: Unsuccessful HTTP response code'
          expect(history.error_backtrace).to be_nil
        end
      end
    end

    def expected_response_hash # rubocop:disable Metrics/MethodLength
      {
        assessment_result: 'eligible',
        applicant: {
          receives_qualifying_benefit: false,
          age_at_submission: 51
        },
        capital: {
          total_liquid: '6771.93',
          total_non_liquid: '3570.51',
          pensioner_capital_disregard: '0.0',
          total_capital: '-86264.36',
          capital_contribution: '0.0',
          liquid_capital_items: [
            {
              description: 'Quia dicta laboriosam pariatur.',
              value: '6771.93'
            }
          ],
          non_liquid_capital_items: [
            {
              description: 'Quidem aspernatur a ducimus.',
              value: '3570.51'
            }
          ]
        },
        property: {
          total_mortgage_allowance: '100000.0',
          total_property: '-100023.77',
          main_home: {
            value: '2290.58',
            transaction_allowance: '68.72',
            allowable_outstanding_mortgage: '9424.94',
            percentage_owned: '0.33',
            net_equity: '-23.77',
            main_home_equity_disregard: '100000.0',
            assessed_equity: '-100023.77',
            shared_with_housing_assoc: true
          },
          additional_properties: []
        },
        vehicles: {
          total_vehicle: '3416.97',
          vehicles: [
            {
              in_regular_use: false,
              included_in_assessment: true,
              value: '3416.97',
              assessed_value: '3416.97',
              date_of_purchase: '2016-11-04',
              loan_amount_outstanding: '3515.61'
            }
          ]
        }
      }
    end
  end
end
