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
    subject { downloader.download(**params) }

    let(:params) do
      {
        aggr_id: 'bucket1',
        aggr_limit: 3,
        url: 'https://foo.bar/a.jpg',
        callback_type: 'my-callback-mechanism',
        callback_dst: 'http://example.com/downloads/myfile',
        user_agent: "Downloader Agent v1.0",
        extra: { product: 1234, actor: 'actor1' },
        request_headers: { "Accept" => "image/*" }
      }
    end
    let(:body_args) do
      [
        params[:aggr_id], params[:aggr_limit], params[:url],
        "", params[:callback_type], params[:callback_dst], "", "",
        nil, nil, params[:user_agent],
        "", params[:extra], params[:request_headers],
        nil, nil, nil
      ]
    end
    let(:post_params) do
      data = params.clone
      data[:extra] = data[:extra].to_json
      data[:request_headers].merge!({"User-Agent" => params[:user_agent]})

      data
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

    it 'builds the body correctly' do
      actual = downloader.send(:build_body, *body_args)
      expect(actual).to eq(post_params)
    end

    it 'calls build_body before performing download' do
      expect(downloader).to receive(:build_body).with(*body_args)
      subject
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

    context 'when s3 is passed as a filestorage without callbacks' do
      let(:params) do
        {
          aggr_id: 'bucket1',
          aggr_limit: 3,
          url: 'https://foo.bar/a.jpg',
          extra: { product: 1234, actor: 'actor1' },
          request_headers: { 'Accept' => 'image/*' },
          s3_bucket: 'mybucketname',
          s3_region: 'eu-west-2'
        }
      end

      let(:body_args) do
        [
          params[:aggr_id], params[:aggr_limit], params[:url],
          "", "", "", "", "",
          nil, nil, params[:user_agent],
          "", params[:extra], params[:request_headers],
          params[:s3_bucket], params[:s3_region], nil
        ]
      end

      let(:post_params) do
        data = params.clone
        data[:callback_type] = ""
        data[:callback_dst] = ""
        data[:extra] = data[:extra].to_json
        data[:request_headers].merge!({"User-Agent" => params[:user_agent]})

        data
      end

      it 'builds the body correctly' do
        actual = downloader.send(:build_body, *body_args)
        expect(actual).to eq(post_params)
      end

      it 'calls build_body before performing download' do
        expect(downloader).to receive(:build_body).with(*body_args)
        subject
      end

      it 'returns ok' do
        expect(subject).to be_a Ferto::Response
        expect(subject.response_code).to eq 201
        expect(subject.job_id).to eq job_id
      end

      context 's3_bucket is missing' do
        it 'does not send the request' do
          params[:s3_bucket] = nil

          expect { subject }.to raise_error ArgumentError
        end
      end

      context 's3_region is missing' do
        it 'does not send the request' do
          params[:s3_region] = nil

          expect { subject }.to raise_error ArgumentError
        end
      end
    end

    context 'when s3 is passed as a filestorage with callbacks' do
      let(:params) do
        {
          aggr_id: 'bucket1',
          aggr_limit: 3,
          url: 'https://foo.bar/a.jpg',
          callback_type: 'my-callback-mechanism',
          callback_dst: 'http://example.com/downloads/myfile',
          extra: { product: 1234, actor: 'actor1' },
          request_headers: { 'Accept' => 'image/*' },
          s3_bucket: 'mybucketname',
          s3_region: 'eu-west-2'
        }
      end

      let(:body_args) do
        [
          params[:aggr_id], params[:aggr_limit], params[:url],
          "", params[:callback_type], params[:callback_dst], "","",
          nil, nil, params[:user_agent],
          "", params[:extra], params[:request_headers],
          params[:s3_bucket], params[:s3_region], nil
        ]
      end

      let(:post_params) do
        data = params.clone
        data[:extra] = data[:extra].to_json
        data[:request_headers].merge!({"User-Agent" => params[:user_agent]})

        data
      end

      it 'builds the body correctly' do
        actual = downloader.send(:build_body, *body_args)
        expect(actual).to eq(post_params)
      end

      it 'calls build_body before performing download' do
        expect(downloader).to receive(:build_body).with(*body_args)
        subject
      end

      it 'returns ok' do
        expect(subject).to be_a Ferto::Response
        expect(subject.response_code).to eq 201
        expect(subject.job_id).to eq job_id
      end

      context 's3_bucket is missing' do
        it 'does not send the request' do
          params[:s3_bucket] = nil

          expect { subject }.to raise_error ArgumentError
        end
      end

      context 's3_region is missing' do
        it 'does not send the request' do
          params[:s3_region] = nil

          expect { subject }.to raise_error ArgumentError
        end
      end
    end

    context 'when subpath is passed' do
      let(:params) do
        {
          aggr_id: 'bucket1',
          aggr_limit: 3,
          url: 'https://foo.bar/a.jpg',
          callback_type: 'my-callback-mechanism',
          callback_dst: 'http://example.com/downloads/myfile',
          extra: { product: 1234, actor: 'actor1' },
          request_headers: { 'Accept' => 'image/*' },
          subpath: 'koko/lala'
        }
      end

      let(:body_args) do
        [
          params[:aggr_id], params[:aggr_limit], params[:url],
          "", params[:callback_type], params[:callback_dst], "", "",
          nil, nil, params[:user_agent],
          "", params[:extra], params[:request_headers],
          nil, nil, params[:subpath]
        ]
      end

      let(:post_params) do
        data = params.clone
        data[:extra] = data[:extra].to_json
        data[:request_headers].merge!({"User-Agent" => params[:user_agent]})

        data
      end

      it 'builds the body correctly' do
        actual = downloader.send(:build_body, *body_args)
        expect(actual).to eq(post_params)
      end

      it 'calls build_body before performing download' do
        expect(downloader).to receive(:build_body).with(*body_args)
        subject
      end

      it 'returns ok' do
        expect(subject).to be_a Ferto::Response
        expect(subject.response_code).to eq 201
        expect(subject.job_id).to eq job_id
      end
    end

    context 'when callback error path is passed' do
      let(:params) do
        {
          aggr_id: 'bucket1',
          aggr_limit: 3,
          url: 'https://foo.bar/a.jpg',
          callback_type: 'my-callback-mechanism',
          callback_dst: 'http://example.com/downloads/myfile',
          callback_error_type: 'my-error-callback-mechanism',
          callback_error_dst: 'http://example.com/downloads/myfailedfile',
          extra: { product: 1234, actor: 'actor1' },
          request_headers: { 'Accept' => 'image/*' }
        }
      end

      let(:body_args) do
        [
          params[:aggr_id], params[:aggr_limit], params[:url],
          "", params[:callback_type], params[:callback_dst],
          params[:callback_error_type], params[:callback_error_dst],
          nil, nil, params[:user_agent],
          "", params[:extra], params[:request_headers],
          params[:s3_bucket], params[:s3_region], nil
        ]
      end

      let(:post_params) do
        data = params.clone
        data[:extra] = data[:extra].to_json
        data[:request_headers].merge!({"User-Agent" => params[:user_agent]})

        data
      end

      it 'builds the body correctly' do
        actual = downloader.send(:build_body, *body_args)
        expect(actual).to eq(post_params)
      end

      it 'calls build_body before performing download' do
        expect(downloader).to receive(:build_body).with(*body_args)
        subject
      end

      it 'returns ok' do
        expect(subject).to be_a Ferto::Response
        expect(subject.response_code).to eq 201
        expect(subject.job_id).to eq job_id
      end
    end
  end
end
