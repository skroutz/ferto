# Changelog

Breaking changes are prefixed with a "[BREAKING]" label.

## master (unreleased)

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
