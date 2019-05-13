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
        callback_type: 'my-callback-mechanism',
        callback_dst: 'http://example.com/downloads/myfile',
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

    context 'when the HTTP notifier backend is selected via callback_url' do
      let(:params) do
        {
          aggr_id: 'bucket1',
          aggr_limit: 3,
          url: 'https://foo.bar/a.jpg',
          callback_url: 'http://example.com/downloads/myfile',
          extra: { product: 1234, actor: 'actor1' }
        }
      end

      it 'returns ok' do
        expect(subject).to be_a Ferto::Response
        expect(subject.response_code).to eq 201
        expect(subject.job_id).to eq job_id
      end
    end

    context "when connection error" do
      before do
        stub_request(:post, downloader_url).
          to_raise(Curl::Err::ConnectionFailedError)
      end

      it "raises Ferto::ConnectionError" do
        expect { subject }.to raise_error(Ferto::ConnectionError)
      end
    end

    context "when a 40X or 50X response code is returned" do
      before do
        stub_request(:post, downloader_url).
          to_return(status: 500,
                    body: "Internal Server Error",
                    headers: { 'Content-Type' => 'Application/json' })
      end

      it "raises Ferto::ResponseError" do
        error_msg = ("An error occured during the download call. "  \
          "Received a 500 response code and body " \
          "Internal Server Error")
        expect { subject }.to raise_error(Ferto::ResponseError, error_msg)
      end
    end

    context 'when a required param is missing' do
      let(:params) do
        {
          aggr_id: 'bucket1',
          aggr_limit: 3,
          # missing 'url' param
          callback_type: 'my-callback-mechanism',
          callback_dst: 'http://example.com/downloads/myfile',
          extra: { product: 1234, actor: 'actor1' }
        }
      end

      it 'does not send the request' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end
end
