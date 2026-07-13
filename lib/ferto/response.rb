module Ferto
  # A point-in-time snapshot of a download response. The underlying
  # Curl::Easy handle is reused by the thread's next download, so every
  # field is captured eagerly here and the handle is not retained.
  class Response
    attr_reader :response_code, :body

    alias body_str body

    def initialize(handle)
      @response_code = handle.response_code
      @body = handle.body
    end

    def job_id
      @job_id ||= body.nil? ? nil : JSON.parse(body)['id']
    end
  end
end
