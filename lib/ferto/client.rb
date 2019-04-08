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

    # @param opts [Hash{Symbol => String, Fixnum}]
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
    # @param url           [String] the resource to be downloaded
    # @param callback_type [String]
    # @param callback_dst  [String] the callback destination
    # @param mime_type     [String] (default: "") accepted MIME types for the
    #   resource
    # @param aggr_id       [String] aggregation identifier
    # @param aggr_limit    [Integer] aggregation concurrency limit
    #
    # @example
    #   client.download(
    #     url: 'http://foo.bar/a.jpg',
    #     callback_type: 'http',
    #     callback_dst: 'http://myapp.com/handle-download',
    #     aggr_id: 'foo', aggr_limit: 3,
    #     mime_type: "image/jpeg",
    #     extra: { something: 'someone' }
    #   )
    #
    # @raise [Ferto::ConnectionError] if there was an error scheduling the
    #   job to downloader
    #
    # @return [Ferto::Response]
    #
    # @see https://github.com/skroutz/downloader/#post-download
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
