module Ferto
  class Response < SimpleDelegator
    def job_id
      @job_id ||= body.nil? ? nil : JSON.parse(body)['id']
    end
  end
end
