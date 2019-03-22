require 'spec_helper'

describe Ferto::Client do
  describe '#initialize' do
    context 'when we are using the default options' do
      subject { Ferto::Client.new }


      let(:default_scheme) { Ferto::DEFAULT_CONFIG[:scheme] }
      let(:default_host) { Ferto::DEFAULT_CONFIG[:host] }
      let(:default_port) { Ferto::DEFAULT_CONFIG[:port] }

      it 'configures the client correctly' do
        expect(subject.scheme).to eq default_scheme
        expect(subject.host).to eq default_host
        expect(subject.port).to eq default_port
      end
    end

    context 'when we are passing different configuration options' do
      subject { Ferto::Client.new(opts) }

      let(:opts) { { host: 'downloader.example.com' } }

      it 'sets the base url correctly' do
        expect(subject.host).to eq opts[:host]
      end
    end
  end

  describe '#download' do
    subject { downloader.download(params) }

    let(:params) do
      {
        aggr_id: 'bucket1',
        aggr_limit: 3,
        url: 'https://foo.bar/a.jpg',
        callback_url: 'http://example.com/downloads/myfile',
        extra: { product: 1234, actor: 'actor1' }
      }
    end
    let(:downloader) { Ferto::Client.new }
    let(:downloader_url) do
      URI::HTTP.build(scheme: downloader.scheme,
                      host: downloader.host,
                      port: downloader.port,
                      path: downloader.path )
    end
    let(:job_id) { 'foobar123' }
    let(:body) { {'id' => job_id}.to_json }

    before do
      stub_request(:post, downloader_url).
        to_return(status: 201,
                  body: body,
                  headers: { 'Content-Type' => 'Application/json' })
    end

    it 'returns ok' do
      expect(subject).to be_a Ferto::Response
      expect(subject.response_code).to eq 201
      expect(subject.job_id).to eq job_id
    end

    context 'when a required param is missing' do
      let(:params) do
        {
          aggr_id: 'bucket1',
          aggr_limit: 3,
          url: 'https://foo.bar/a.jpg',
          extra: { product: 1234, actor: 'actor1' }
        }
      end

      it 'does not send the request' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end
end
