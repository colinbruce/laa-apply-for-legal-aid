require 'rails_helper'

RSpec.describe 'check merits answers requests', type: :request do
  include ActionView::Helpers::NumberHelper

  describe 'GET /providers/applications/:id/check_merits_answers' do
    let(:application) do
      create :legal_aid_application,
             :with_everything,
             :means_completed
    end

    subject { get "/providers/applications/#{application.id}/check_merits_answers" }

    context 'unauthenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'logged in as an authenticated provider' do
      before do
        login_as application.provider
        subject
      end

      it 'displays the correct page' do
        expect(unescaped_response_body).to include('Check your answers')
      end

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays the correct questions' do
        scope = 'shared.check_answers.merits.items'
        expect(response.body).to include(I18n.t('notification_of_latest_incident', scope: scope))
        expect(response.body).to include(I18n.t('date_of_latest_incident', scope: scope))
        expect(response.body).to include(I18n.t('understands_terms_of_court_order', scope: scope))
        expect(response.body).to include(I18n.t('warning_letter_sent', scope: scope))
        expect(response.body).to include(I18n.t('police_notified', scope: scope))
        expect(response.body).to include(I18n.t('bail_conditions_set', scope: scope))
        expect(response.body).to include(I18n.t('statement_of_case', scope: scope))
        expect(response.body).to include(I18n.t('prospects_of_success', scope: scope))
        expect(response.body).to include(I18n.t('success_prospect', scope: scope))
      end

      it 'displays the correct URLs for changing values' do
        expect(response.body).to have_change_link(:incident_details, providers_legal_aid_application_date_client_told_incident_path)
        expect(response.body).to have_change_link(:respondent_details, providers_legal_aid_application_respondent_path)
        expect(response.body).to have_change_link(:statement_of_case, providers_legal_aid_application_statement_of_case_path(application))
        expect(response.body).to have_change_link(:success_likely, providers_legal_aid_application_success_likely_index_path)
      end

      it 'displays the question When did your client tell you about the latest domestic abuse incident' do
        expect(response.body).to include(I18n.t('shared.forms.date_input_fields.told_on_label'))
        expect(response.body).to include(application.latest_incident.told_on.to_s)
      end

      it 'displays the question When did the incident occur?' do
        expect(response.body).to include(I18n.t('shared.forms.date_input_fields.occurred_on_label'))
        expect(response.body).to include(application.latest_incident.occurred_on.to_s)
      end

      it 'displays the details of whether the respondent understands the terms of court order' do
        expect(response.body).to include(application.respondent.understands_terms_of_court_order_details)
      end

      it 'displays the details of whether a warning letter has been sent' do
        expect(response.body).to include(application.respondent.warning_letter_sent_details)
      end

      it 'displays the details of whether the police has been notified' do
        expect(response.body).to include(application.respondent.police_notified_details)
      end

      it 'displays the details of whether the bail conditions have been set' do
        expect(response.body).to include(application.respondent.bail_conditions_set_details)
      end

      it 'displays the statement of case' do
        expect(response.body).to include(application.statement_of_case.statement)
      end

      it 'displays the warning text When did the incident occur?' do
        expect(response.body).to include(I18n.t('shared.forms.date_input_fields.occurred_on_label'))
        expect(response.body).to include(application.latest_incident.occurred_on.to_s)
      end

      it 'displays the warning text' do
        expect(response.body).to include(I18n.t('providers.check_merits_answers.show.sign_app_text'))
      end

      it 'should change the state to "checking_merits_answers"' do
        expect(application.reload.checking_merits_answers?).to be_truthy
      end

      it 'has a back link to the client declaration page' do
        expect(response.body).to have_back_link(reset_providers_legal_aid_application_check_merits_answers_path)
      end
    end
  end

  describe 'PATCH /providers/applications/:id/check_merits_answers/continue' do
    let(:application) do
      create :legal_aid_application,
             :with_everything,
             :checking_merits_answers
    end
    let(:params) { {} }
    subject do
      patch "/providers/applications/#{application.id}/check_merits_answers/continue", params: params
    end

    context 'logged in as an authenticated provider' do
      before do
        login_as application.provider
      end

      it 'redirects to next page' do
        expect(subject).to redirect_to(providers_legal_aid_application_merits_declaration_path(application))
      end

      it 'transitions to checked_merits_answers state' do
        subject
        expect(application.reload.may_generate_reports?).to be true
      end

      #it 'updates the record' do
      #  application.create_merits_assessment!
      #  expect { subject }.to change { application.merits_assessment.reload.submitted_at }.from(nil)
      #  expect(application.reload).to be_generating_reports
      #end

      context 'Form submitted using Save as draft button' do
        let(:params) { { draft_button: 'Save as draft' } }

        it "redirect provider to provider's applications page" do
          subject
          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end

        it 'sets the application as draft' do
          subject
          expect(application.reload).to be_draft
        end
      end
    end

    context 'unauthenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end
  end

  describe 'PATCH "/providers/applications/:id/check_merits_answers/reset' do
    let(:application) do
      create :legal_aid_application,
             :with_everything,
             :checking_merits_answers
    end

    subject { patch "/providers/applications/#{application.id}/check_merits_answers/reset" }

    context 'unauthenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'logged in as an authenticated provider' do
      before do
        login_as application.provider
        get providers_legal_aid_application_merits_declaration_path(application)
        get providers_legal_aid_application_check_merits_answers_path(application)
        subject
      end

      it 'transitions to means_completed state' do
        expect(application.reload.means_completed?).to be true
      end

      describe 'redirection' do
        it 'redirects to client declaration page' do
          expect(response).to redirect_to providers_legal_aid_application_merits_declaration_path(application, back: true)
        end
      end
    end
  end
end
