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
    # @param aggr_proxy    [String] the HTTP proxy to use for downloading the
    #   resource, by default no proxy is used. The proxy is set up on
    #   aggregation level and it cannot be updated for an existing aggregation.
    # @param download_timeout [Integer] the maximum time to wait for the
    #   resource to be downloaded in seconds, by default there is no timeout
    # @param user_agent [String] the User-Agent string to use for
    #   downloading the resource, by default it uses the User-Agent string
    #   set in the downloader's configuration
    # @param request_headers [Hash] the request headers that will be used
    #   in downloader when performing the actual request in order to fetch
    #   the desired resource
    #
    # @example
    #   client.download(
    #     url: 'http://foo.bar/a.jpg',
    #     callback_type: 'http',
    #     callback_dst: 'http://myapp.com/handle-download',
    #     aggr_id: 'foo', aggr_limit: 3,
    #     download_timeout: 120,
    #     aggr_proxy: 'http://myproxy.com/',
    #     user_agent: 'my-useragent',
    #     mime_type: "image/jpeg",
    #     request_headers: { "Accept" => "image/*,*/*;q=0.8" },
    #     extra: { something: 'someone' }
    #   )
    #
    # @raise [Ferto::ConnectionError] if there was an error scheduling the
    #   job to downloader with respect to the fact that a Curl ConnectionFailedError occured
    # @raise [Ferto::ResponseError] if a response code of 40X or 50X is received
    #
    # @return [Ferto::Response]
    #
    # @see https://github.com/skroutz/downloader/#post-download
    def download(aggr_id:, aggr_limit: @aggr_limit, url:,
                 aggr_proxy: nil, download_timeout: nil, user_agent: nil,
                 callback_url: "", callback_dst: "",
                 callback_type: "", mime_type: "", extra: {},
                 request_headers: {})
      uri = URI::HTTP.build(
        scheme: scheme, host: host, port: port, path: path
      )
      body = build_body(
        aggr_id, aggr_limit, url,
        callback_url, callback_type, callback_dst,
        aggr_proxy, download_timeout, user_agent,
        mime_type, extra, request_headers
      )
      # Curl.post reuses the same handler
      begin
        res = Curl.post(uri.to_s, body.to_json) do |handle|
          handle.headers = build_header(aggr_id)
          handle.connect_timeout = connect_timeout
          handle.timeout = timeout
        end

        case res.response_code
        when 400..599
          error_msg = ("An error occured during the download call. "  \
            "Received a #{res.response_code} response code and body " \
            "#{res.body_str}")
          raise Ferto::ResponseError.new(error_msg, res)
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
                   callback_dst, aggr_proxy, download_timeout, user_agent,
                   mime_type, extra, request_headers)
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

      body[:aggr_proxy] = aggr_proxy if aggr_proxy
      body[:download_timeout] = download_timeout if download_timeout
      body[:user_agent] = user_agent if user_agent

      if !extra.nil?
        body[:extra] = extra.is_a?(Hash) ? extra.to_json : extra.to_s
      end

      # We will continue to expose the user_agent field just like tools
      # like curl and wget do. Along with that we will follow their paradigm
      # where if both a user-agent flag and a `User-Agent` in the request headers
      # are provided then the user agent in the request headers is preferred.
      #
      # Also if the `user_agent` is provided but the request headers do not
      # contain a `User-Agent` key, then the `user_agent` is copied to the headers
      if user_agent && !request_headers.key?("User-Agent")
        request_headers["User-Agent"] = user_agent
      end

      body[:request_headers] = request_headers

      body
    end
  end
end
