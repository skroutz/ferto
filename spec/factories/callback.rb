FactoryBot.define do
  factory :downloader_callback_params, aliases: [:successful_callback], class: OpenStruct do
    success { true }
    error { '' }
    download_url { Faker::Internet.url }
    resource_url { Faker::Internet.url }
    job_id { SecureRandom.urlsafe_base64(14) }
    response_code { 200 }
    extra { { 'groupno' => 'foobar' }.to_json }

    factory :unsuccessful_callback do
      success { false }

      trait :with_404 do
        error { 'Received Status code 404' }
        response_code { 404 }
      end

      trait :with_TLS do
        error { 'TLS Error Occured: dial: x509: certificate' }
        response_code { 0 }
      end

      trait :with_mime do
        error { 'Expected mime-type to be (image/jpeg), found (image/png)' }
        response_code { 200 }
      end
    end
  end
end
