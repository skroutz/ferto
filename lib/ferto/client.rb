require "curl"
require "json"

module Ferto
  class Client
    # @return [String]
    attr_reader :scheme

    # @return [String]
    attr_reader :host

    # @return [String] The Downloader service path for enqueueing new downloads.
    attr_reader :path

    # @return [String]
    attr_reader :port

    # @return [Fixnum]
    attr_reader :connect_timeout

    # @return [Fixnum] The maximum time in seconds that you allow the `libcurl`
    #   transfer operation to take.
    attr_reader :timeout

    # @return [Fixnum] The maximum concurrent download requests that you allow
    #   the service to make.
    attr_reader :aggr_limit

    # @param [Hash{Symbol => String, Fixnum}]
    # @option opts [String] :scheme
    # @option opts [String] :host
    # @option opts [String] :path
    # @option opts [Fixnum] :port
    # @option opts [Fixnum] :connect_timeout
    # @option opts [Fixnum] :timeout
    # @option opts [Fixnum] :aggr_limit
    def initialize(opts = {})
      opts = DEFAULT_CONFIG.merge(opts)
      @scheme = opts[:scheme]
      @host = opts[:host]
      @path = opts[:path]
      @port = opts[:port]
      @connect_timeout = opts[:connect_timeout]
      @timeout = opts[:timeout]
      @aggr_limit = opts[:aggr_limit]
    end

    # Sends a request to Downloader and returns its reply.
    #
    # @example
    #   downloader = Ferto::Client.new
    #   dl_resp = downloader.download(
    #     aggr_id: 'msystems',
    #     aggr_limit: 3,
    #     url: 'http://foo.bar/a.jpg',
    #     callback_type: 'http',
    #     callback_dst: 'http://example.com/downloads/myfile',
    #     extra: { groupno: 'foobar' }
    #   )
    #
    # @raise [Ferto::ConnectionError] if the client failed to connect to the
    #   downloader API
    #
    # @return [Ferto::Response]
    def download(aggr_id:, aggr_limit: @aggr_limit, url:,
                 callback_url: "", callback_dst: "",
                 callback_type: "", mime_type: "", extra: {})
      uri = URI::HTTP.build(
        scheme: scheme, host: host, port: port, path: path
      )
      body = build_body(
        aggr_id, aggr_limit, url, callback_url, callback_type, callback_dst,
        mime_type, extra
      )
      # Curl.post reuses the same handler
      begin
        res = Curl.post(uri.to_s, body.to_json) do |handle|
          handle.headers = build_header(aggr_id)
          handle.connect_timeout = connect_timeout
          handle.timeout = timeout
        end
      rescue Curl::Err::ConnectionFailedError => e
        raise Ferto::ConnectionError.new(e)
      end

      Ferto::Response.new res
    end

    private

    def build_header(aggr_id)
      {
        'Content-Type': 'application/json',
        'X-Aggr': aggr_id.to_s
      }
    end

    def build_body(aggr_id, aggr_limit, url, callback_url, callback_type,
                   callback_dst, mime_type, extra)
      body = {
        aggr_id: aggr_id,
        aggr_limit: aggr_limit,
        url: url
      }

      if callback_url.empty?
        body[:callback_type] = callback_type
        body[:callback_dst] = callback_dst
      else
        body[:callback_url] = callback_url
      end

      if !mime_type.empty?
        body[:mime_type] = mime_type
      end

      if !extra.nil?
        body[:extra] = extra.is_a?(Hash) ? extra.to_json : extra.to_s
      end

      body
    end
  end
end
