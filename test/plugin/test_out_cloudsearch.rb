require 'helper'

class CloudSearchOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    endpoint http://example.com
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::CloudSearchOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }

    d = create_driver %[
      endpoint http://example.com
      profile_name foo-doc
      buffer_chunk_limit 4M
    ]
    assert_equal 'http://example.com', d.instance.endpoint
    assert_equal 'ap-northeast-1', d.instance.region
    assert_equal 'foo-doc', d.instance.profile_name
    assert_equal nil, d.instance.access_key_id
    assert_equal nil, d.instance.secret_access_key
    assert_equal 4*1024*1024, d.instance.buffer.buffer_chunk_limit

    d = create_driver %[
      endpoint http://example.com
      buffer_chunk_limit 5M
      access_key_id ackey
      secret_access_key seckey 
    ]
    assert_equal 4.5*1024*1024, d.instance.buffer.buffer_chunk_limit
    assert_equal nil, d.instance.profile_name
    assert_equal 'ackey', d.instance.access_key_id
    assert_equal 'seckey', d.instance.secret_access_key

  end

  def test_format
    d = create_driver
  end

  def test_write
    d = create_driver
  end
end
