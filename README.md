# Ferto

[![Build Status](https://travis-ci.org/skroutz/ferto.svg?branch=master)](https://travis-ci.org/skroutz/ferto)
[![Gem Version](https://badge.fury.io/rb/ferto.svg)](https://badge.fury.io/rb/ferto)
[![Documentation](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/skroutz/ferto)

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

[downloader](https://github.com/skroutz/downloader) supports multiple
notification backends for the download results. Currently, there are two
supported options: an HTTP and a Kafka backend. Let's see how to issue a
download request in each case:

#### HTTP-based notification backend

```ruby
dl_resp = client.download(aggr_id: 'bucket1',
                          aggr_limit: 3,
                          url: 'http://example.com/',
                          mime_type: 'text/html',
                          callback_type: 'http',
                          callback_dst: 'http://myservice.com/downloader_callback',
                          extra: { some_extra_info: 'info' })
```

In order for a service to consume downloader's result, it *must* accept the HTTP
callback in the endpoint denoted by `callback_dst`.

#### Kafka-based notification backend

```ruby
dl_resp = client.download(aggr_id: 'bucket1',
                          aggr_limit: 3,
                          url: 'http://example.com/',
                          mime_type: 'text/html',
                          callback_type: 'kafka',
                          callback_dst: 'my-kafka-topic',
                          extra: { some_extra_info: 'info' })
```

To consume the downloader's result, you can use your favorite Kafka library and
consume the callback message from `my-kafka-topic` (passed in `callback_dst`).

If the connection with the `downloader` API was successful, the aforementioned
`dl_resp` is a
[`Ferto::Response`](https://github.com/skroutz/ferto/blob/master/lib/ferto/response.rb#L2)
object. If the client failed to connect, a
[`Ferto::ConnectionError`](https://github.com/skroutz/ferto/blob/master/lib/ferto.rb#L18)
exception is raised.

To handle the actual callback message, e.g. from inside a Rails controller:

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

> For the detailed semantics of each option and the format of the callback
> payload, please, refer to the official downloader's documentation ([download
> parameters](https://github.com/skroutz/downloader#endpoints), [callback
> payload](https://github.com/skroutz/downloader/tree/kafka-backend#usage)).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/skroutz/ferto.
