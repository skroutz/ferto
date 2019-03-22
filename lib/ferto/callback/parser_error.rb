module Ferto
  class Callback::ParserError < StandardError
    attr_reader :params

    def initialize(params = nil, msg = 'Callback parsing error')
      @params = params
      super(msg)
    end
  end
end
