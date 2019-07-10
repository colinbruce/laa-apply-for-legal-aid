require 'rails_helper'

RSpec.describe ProviderDetailsRetriever do
  let(:api_url) { 'https://sitsoa10.laadev.co.uk/CCMSInformationService/api/providerDetails' }
  let(:mock) { true }
  let(:provider) { create :provider, :username_with_special_characters }

  subject { described_class.call(provider.username) }

  before do
    allow(Rails.configuration.x.provider_details).to receive(:url).and_return(api_url)
    allow(Rails.configuration.x.provider_details).to receive(:mock).and_return(mock)
  end

  describe '.call' do
    shared_examples_for 'get response from API' do
      let(:escaped_username) { CGI.escape(provider.username) }

      it 'returns the expected data structure' do
        expected_keys = %i[providerOffices contactId contactName]
        expect(subject.keys).to match_array(expected_keys)

        expected_office_keys = %i[providerfirmId officeId officeName smsVendorNum smsVendorSite]
        expect(subject[:providerOffices][0].keys).to match_array(expected_office_keys)
      end

      it 'encode properly the username' do
        expect(URI).to receive(:parse).at_least(:once).with(/#{escaped_username}/).and_call_original
        subject
      end
    end

    context 'with fake API', vcr: { cassette_name: 'provider_details_api_mock' } do
      it_behaves_like 'get response from API'
    end

    context 'with real API', vcr: { cassette_name: 'provider_details_api_real' } do
      let(:provider) { create :provider, :with_provider_details_api_username }
      let(:mock) { false }

      it_behaves_like 'get response from API'
    end

    context 'on failure' do
      before do
        allow(Net::HTTP).to receive(:get_response).and_return(OpenStruct.new)
      end

      it 'raises error' do
        expect { subject }.to raise_error(described_class::ApiError)
      end
    end
  end
end