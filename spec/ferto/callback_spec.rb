require 'spec_helper'

describe Ferto::Callback do
  subject { Ferto::Callback.new(params) }

  describe 'success' do
    context 'when successful' do
      let(:params) { FactoryBot.build(:successful_callback) }

      it 'processes the download url' do
        expect(subject).to be_download_successful
      end
    end

    context 'when there are errors' do
      context 'when there is a tls error' do
        let(:params)  do
          FactoryBot.build(:unsuccessful_callback, :with_TLS)
        end

        it 'raises a Download related error' do
          expect(subject).not_to be_download_successful
        end
      end

      context 'when there is a mime-type error' do
        let(:params) { FactoryBot.build(:unsuccessful_callback, :with_mime) }

        it 'detects the mime type' do
          expect(subject).not_to be_download_successful
          expect(subject).to be_mime_error
        end
      end
    end
  end

  describe '#matching_url?' do
    let(:params) { FactoryBot.build(:successful_callback) }

    context 'when checking different URLs' do
      let(:url) { 'https://httpbin.org/different_image/png' }

      it { is_expected.not_to be_matching_url(url) }
    end

    context 'when checking the same URLs' do
      let(:url) { subject.resource_url }

      it { is_expected.to be_matching_url(url) }
    end
  end

  describe '#mime_error?' do
    context "when there isn't any mime error" do
      let(:params) { FactoryBot.build(:successful_callback) }

      it { is_expected.not_to be_mime_error }
    end

    context 'when there is a mime error' do
      let(:params) { FactoryBot.build(:unsuccessful_callback, :with_mime) }

      it { is_expected.to be_mime_error }
    end
  end
end
