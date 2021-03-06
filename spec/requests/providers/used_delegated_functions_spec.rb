require 'rails_helper'
RSpec.describe Providers::UsedDelegatedFunctionsController, type: :request, vcr: { cassette_name: 'gov_uk_bank_holiday_api' } do
  let(:legal_aid_application) { create :legal_aid_application }
  let(:login_provider) { login_as legal_aid_application.provider }
  let(:mocked_email_service) { instance_double(SubmitApplicationReminderService, send_email: {}) }

  before do
    login_provider
    subject
  end

  describe 'GET /providers/applications/:legal_aid_application_id/used_delegated_functions' do
    subject do
      get providers_legal_aid_application_used_delegated_functions_path(legal_aid_application)
    end

    it 'renders successfully' do
      expect(response).to have_http_status(:ok)
    end

    context 'dynamic date hint text' do
      it 'contains a valid date' do
        hint_text_date = Time.zone.now.ago(5.days).strftime('%d %m %Y')

        subject
        expect(response.body).to include(hint_text_date)
      end
    end

    context '#pre_dwp_check?' do
      it 'returns true' do
        expect(described_class.new.pre_dwp_check?).to be true
      end
    end

    context 'when not authenticated' do
      let(:login_provider) { nil }
      it_behaves_like 'a provider not authenticated'
    end
  end

  describe 'PATCH /providers/applications/:legal_aid_application_id/used_delegated_functions' do
    let!(:proceeding_type) { create(:proceeding_type) }
    let!(:default_substantive_scope_limitation) do
      create :scope_limitation,
             :substantive_default,
             joined_proceeding_type: proceeding_type,
             meaning: 'Default substantive SL'
    end
    let!(:default_delegated_function_scope_limitation) do
      create :scope_limitation,
             :delegated_functions_default,
             joined_proceeding_type: proceeding_type,
             meaning: 'Default delegated functions SL'
    end
    let!(:legal_aid_application) do
      create :legal_aid_application,
             :with_passported_state_machine,
             proceeding_types: [proceeding_type],
             scope_limitations: [default_substantive_scope_limitation]
    end
    let(:used_delegated_functions_on) { rand(20).days.ago.to_date }
    let(:day) { used_delegated_functions_on.day }
    let(:month) { used_delegated_functions_on.month }
    let(:year) { used_delegated_functions_on.year }
    let(:used_delegated_functions) { true }
    let(:params) do
      {
        legal_aid_application: {
          used_delegated_functions_day: day.to_s,
          used_delegated_functions_month: month.to_s,
          used_delegated_functions_year: year.to_s,
          used_delegated_functions: used_delegated_functions.to_s
        }
      }
    end
    let(:button_clicked) { {} }

    before do
      allow(SubmitApplicationReminderService).to receive(:new).with(legal_aid_application).and_return(mocked_email_service)
      patch(
        providers_legal_aid_application_used_delegated_functions_path(legal_aid_application),
        params: params.merge(button_clicked)
      )
    end

    it 'updates the application' do
      legal_aid_application.reload
      expect(legal_aid_application.used_delegated_functions_on).to eq(used_delegated_functions_on)
      expect(legal_aid_application.used_delegated_functions).to eq(used_delegated_functions)
    end

    it 'redirects to the limitations page' do
      expect(response).to redirect_to(providers_legal_aid_application_limitations_path(legal_aid_application))
    end

    context 'when not authenticated' do
      let(:login_provider) { nil }
      it_behaves_like 'a provider not authenticated'
    end

    context 'when date incomplete' do
      let(:month) { '' }

      it 'renders show' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays error' do
        expect(response.body).to include('govuk-error-summary')
        expect(response.body).to include(I18n.t('activemodel.errors.models.legal_aid_application.attributes.used_delegated_functions_on.date_not_valid'))
      end
    end

    context 'date is not in range' do
      let(:year) { 2018 }
      let(:month) { 10 }
      let(:day) { 1 }

      it 'renders show' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays error' do
        hint_text_date = Time.zone.now.ago(12.months).strftime('%d %m %Y')

        subject
        translation_path = 'activemodel.errors.models.legal_aid_application.attributes.used_delegated_functions_on.date_not_in_range'
        expect(response.body).to include(I18n.t(translation_path, months: hint_text_date))
      end
    end

    context 'when date contains alpha characters' do
      let(:params) do
        {
          legal_aid_application: {
            used_delegated_functions_day: day.to_s,
            used_delegated_functions_month: '5s',
            used_delegated_functions_year: year.to_s,
            used_delegated_functions: used_delegated_functions.to_s
          }
        }
      end
      it 'renders show' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays error' do
        expect(response.body).to include('govuk-error-summary')
        expect(response.body).to include(I18n.t('activemodel.errors.models.legal_aid_application.attributes.used_delegated_functions_on.date_not_valid'))
      end
    end

    context 'when date not entered' do
      let(:day) { '' }
      let(:month) { '' }
      let(:year) { '' }

      it 'renders show' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays error' do
        expect(response.body).to include('govuk-error-summary')
        expect(response.body).to include(I18n.t('activemodel.errors.models.legal_aid_application.attributes.used_delegated_functions_on.blank'))
      end
    end

    context 'when not using delegated functions' do
      let(:used_delegated_functions) { false }

      it 'updates the application' do
        legal_aid_application.reload
        expect(legal_aid_application.used_delegated_functions_on).to be_nil
        expect(legal_aid_application.used_delegated_functions).to eq(used_delegated_functions)
        expect(legal_aid_application.scope_limitations).to eq [default_substantive_scope_limitation]
      end

      it 'redirects to the online banking page' do
        expect(response).to redirect_to(providers_legal_aid_application_limitations_path(legal_aid_application))
      end

      it 'does not send a reminder email' do
        expect(SubmitApplicationReminderService).not_to have_received(:new).with(legal_aid_application)
      end
    end

    context 'Form submitted using Save as draft button' do
      let(:button_clicked) { { draft_button: 'Save as draft' } }

      it "redirects provider to provider's applications page" do
        expect(response).to redirect_to(providers_legal_aid_applications_path)
      end

      it 'updates the application' do
        legal_aid_application.reload
        expect(legal_aid_application.used_delegated_functions_on).to eq(used_delegated_functions_on)
        expect(legal_aid_application.used_delegated_functions).to eq(used_delegated_functions)
        expect(legal_aid_application.scope_limitations).to match_array [default_substantive_scope_limitation, default_delegated_function_scope_limitation]
      end

      context 'when date incomplete' do
        let(:month) { '' }

        it 'renders show' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays error' do
          expect(response.body).to include('govuk-error-summary')
          expect(response.body).to include(I18n.t('activemodel.errors.models.legal_aid_application.attributes.used_delegated_functions_on.date_not_valid'))
        end
      end

      context 'when date not entered' do
        let(:day) { '' }
        let(:month) { '' }
        let(:year) { '' }

        it "redirects provider to provider's applications page" do
          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end

        it 'updates the application' do
          legal_aid_application.reload
          expect(legal_aid_application.used_delegated_functions_on).to be_nil
          expect(legal_aid_application.used_delegated_functions).to eq(used_delegated_functions)
        end
      end
    end
  end
end
