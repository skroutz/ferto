require 'ferto/version'
require 'ferto/client'
require 'ferto/response'
require 'ferto/callback'
require 'ferto/callback/parser_error'

module Ferto
  DEFAULT_CONFIG = {
    scheme: 'http',
    host: 'localhost',
    port: 8000,
    path: '/download',
    connect_timeout: 4,
    timeout: 6,
    aggr_limit: 4
  }.freeze

  class ConnectionError < StandardError; end
  
  # A custom error class for 40X and 50X responses
  class ResponseError < StandardError
    
    # Initialize a Ferto::ResponseError
    #
    # @param [String] err A string describing the error occured
    # @param [Curl::Easy | nil] response a Curl::Easy object
    #   that represents the response returned by the download method.
    #   Default: nil
    def initialize(err, response=nil)
      super(err)
      @response = response
    end

    # response is set, during the download in case of
    # 40X or 50X responses are returned, so that it
    # can be used in case of debugging but it is also 
    # included for reasons of completeness.
    attr_reader :response
  end
end
