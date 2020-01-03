require 'rails_helper'

module Dashboard
  module WidgetDataProviders
    RSpec.describe Applications do
      describe '.handle' do
        it 'returns the unqualified widget name' do
          expect(described_class.handle).to eq 'applications'
        end
      end

      describe '.dataset_definition' do
        it 'returns hash of field definitions' do
          expected_definition = { "fields":
                                    [
                                      { "name": 'Date', "type": 'date' },
                                      { "name": 'Started applications', "optional": false, "type": 'number' },
                                      { "name": 'Submitted applications', "optional": false, "type": 'number' },
                                      { "name": 'Total submitted applications', "optional": false, "type": 'number' },
                                      { "name": 'Failed applications', "optional": false, "type": 'number' },
                                      { "name": 'Delegated function applications', "optional": false, "type": 'number' }
                                    ], "unique_by": ['date'] }.to_json
          expect(described_class.dataset_definition.to_json).to eq expected_definition
        end
      end

      describe '.data' do
        before { create_apps }
        let(:date) { Date.new(2019, 12, 12) }
        it 'returns the expected data' do
          travel_to(date) { expect(described_class.data).to eq expected_data }
        end

        def expected_data
          [
            { 'date' => '2019-12-06', 'started_apps' => 5, 'submitted_apps' => 2, 'total_submitted_apps' => 2, 'failed_apps' => 0, 'delegated_func_apps' => 0 },
            { 'date' => '2019-12-07', 'started_apps' => 3, 'submitted_apps' => 1, 'total_submitted_apps' => 3, 'failed_apps' => 1, 'delegated_func_apps' => 0 },
            { 'date' => '2019-12-08', 'started_apps' => 1, 'submitted_apps' => 0, 'total_submitted_apps' => 3, 'failed_apps' => 0, 'delegated_func_apps' => 1 },
            { 'date' => '2019-12-09', 'started_apps' => 1, 'submitted_apps' => 0, 'total_submitted_apps' => 3, 'failed_apps' => 0, 'delegated_func_apps' => 0 },
            { 'date' => '2019-12-10', 'started_apps' => 8, 'submitted_apps' => 3, 'total_submitted_apps' => 6, 'failed_apps' => 0, 'delegated_func_apps' => 0 },
            { 'date' => '2019-12-11', 'started_apps' => 5, 'submitted_apps' => 0, 'total_submitted_apps' => 6, 'failed_apps' => 0, 'delegated_func_apps' => 2 },
            { 'date' => '2019-12-12', 'started_apps' => 2, 'submitted_apps' => 1, 'total_submitted_apps' => 7, 'failed_apps' => 0, 'delegated_func_apps' => 0 }
          ]
        end

        def expected_apps
          # pattern is days_ago => [created applications, merits_assessments submitted, ccms_submission failures, delegated_function applications]
          {
            6 => [3, 2, 0, 0],
            5 => [1, 1, 1, 0],
            4 => [0, 0, 0, 1],
            3 => [1, 0, 0, 0],
            2 => [5, 3, 0, 0],
            1 => [3, 0, 0, 2],
            0 => [1, 1, 0, 0]
          }
        end

        def create_apps
          expected_apps.each do |num_days, num_apps|
            travel_to(date - num_days.days) do
              FactoryBot.create_list :legal_aid_application, num_apps[0]
              FactoryBot.create_list :merits_assessment, num_apps[1], submitted_at: Date.today
              FactoryBot.create_list :ccms_submission, num_apps[2], aasm_state: 'failed'
              FactoryBot.create_list :legal_aid_application, num_apps[3], :with_delegated_functions
            end
          end
        end
      end
    end
  end
end