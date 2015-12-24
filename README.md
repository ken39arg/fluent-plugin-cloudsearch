# Fluent::Plugin::Cloudsearch

Send yourr logs to cloudsearch.

https://aws.amazon.com/jp/cloudsearch/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-cloudsearch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-cloudsearch

## Usage

```
<match my.logs>
  type cloudsearch 
  endpoint http://my-cloudsearch-document-endpoint.example.com
  region   us-east

  # access_key & secret_access_key
  access_key_id MYACCESSKEY
  secret_access_key MYSECRETKEY

  # for shared credentials
  profile_name MYPROFILENAME

  # maximum and default buffer_chunk_limit is 4.5MB
  buffer_chunk_limit 4.5M
</match>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ken39arg/fluent-plugin-cloudsearch. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

