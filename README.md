# Ferto

[![Build Status](https://travis-ci.org/skroutz/ferto.svg?branch=master)](https://travis-ci.org/skroutz/ferto)
[![Gem Version](https://badge.fury.io/rb/ferto.svg)](https://badge.fury.io/rb/ferto)

A Ruby client for [skroutz/downloader](https://github.com/skroutz/downloader).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ferto'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ferto

## Usage

### Creating a client

```ruby
client = Ferto::Client.new(
  scheme: 'http',
  host: 'localhost',
  port: 8000
)
```

### Downloading a file

```ruby
client.download(aggr_id: 'bucket1',
                aggr_limit: '3',
                url: 'http://example.com/',
                mime_type: 'text/html',
                callback_url: 'http://myservice.com/downloader_callback',
                extra: { some_extra_info: 'info' })

```

For the semantics of those options refer to [downloader's documentation](https://github.com/skroutz/downloader#endpoints)


In order for a service to consume downloader's result, it must accept the HTTP
callback in some endpoint passed in `callback_url`.

To consume the callback, e.g. from inside a Rails controller:

```ruby
class DownloaderController < ApplicationConroller
  def callback
    cb = Ferto::Callback.new(callback_params)

    if cb.download_successful?
      # Download cb.download_url
    else
      # Log failure
    end
  end

  def callback_params
    params.permit!.to_h
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/skroutz/ferto.
