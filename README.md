# Cenit OAuth

Engine that provides controllers and models for Cenit OAuth 2.0 protocol

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cenit-oauth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cenit-oauth

## Usage

Cenit mount this oauth engine if the option `oauth_token_end_point` is set to `embedded`.

To run this engine in a different application, which is convenient for asynchronous request operations, just mount it in such application.
If you do that them you may wish to set `oauth_token_end_point` option to an other value but `embedded`.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cenit-service/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
