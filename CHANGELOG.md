# Changelog

Breaking changes are prefixed with a "[BREAKING]" label.

## master (unreleased)

## 0.1.1 (2026-07-11)

- Manage a per-thread `Curl::Easy` handle in `Client#download` instead of
  relying on `Curl.post`, whose per-thread handle cache was removed in curb
  1.3.6. Restores keep-alive connection reuse towards the downloader and
  prevents open-connection pile-up in long-lived workers.
  Note: like every setup before curb 1.3.6, the long-lived cached handle is
  only safe under GC compaction with curb >= 1.3.7 (or a build carrying the
  `curl_easy_mark` pin fix). The gemspec intentionally leaves curb
  unconstrained — the consuming app owns the curb version.
- [BREAKING] `Ferto::Response` is now a plain snapshot object instead of a
  `SimpleDelegator` around the `Curl::Easy` handle: `response_code` and `body`
  (aliased as `body_str`) are captured when the response is built, so a
  response held across `download` calls keeps its own data instead of
  exposing the reused handle's next request. Other `Curl::Easy` methods are
  no longer forwarded.
- [BREAKING] `Ferto::ResponseError#response` now returns a `Ferto::Response`
  snapshot instead of the live `Curl::Easy` handle, which a subsequent
  `download` on the same thread would have reset.
- Add compatibility for Ruby 3.4 and 3.5

## 0.1.0 (2023-06-16)

 - Add compatibility for Ruby 3
   - Unpin curb version from gemspec
   - Unpin faker version
   - specs: Pass params as kwargs instead of hash

## 0.0.9 (2022-11-14)

### Added

- Support for different callbacks when a job fails [[#13](https://github.com/skroutz/ferto/pull/13)]

## 0.0.8 (2022-08-16)

### Added

- Support for setting subpath in download requests [[#12](https://github.com/skroutz/ferto/pull/12)]

## 0.0.6 (2019-07-09)

### Added

- Support for setting request headers in download requests [[#10](https://github.com/skroutz/ferto/pull/10)]

## 0.0.7 (2022-07-21)

### Added

- Support for setting AWS S3 bucket as filestorage solution [[#11](https://github.com/skroutz/ferto/pull/11)]

## 0.0.5 (2019-05-16)

### Added

- [BREAKING] `Ferto::ResponseError` exception raising when 40X or 50X response is returned [[#9](https://github.com/skroutz/ferto/pull/9)]

## 0.0.4 (2019-04-18)

### Added

- Support setting a job download timeout [[#7](https://github.com/skroutz/ferto/pull/7)]
- Support setting an HTTP proxy for use in download requests [[#7](https://github.com/skroutz/ferto/pull/7)]
- Support setting the User-Agent header in download requests [[#7](https://github.com/skroutz/ferto/pull/7)]
