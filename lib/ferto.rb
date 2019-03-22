require 'ferto/version'
require 'ferto/client'
require 'ferto/response'
require 'ferto/callback'

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
end
