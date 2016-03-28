require 'helper'
require 'json'
require 'aws-sdk'

require 'test/unit/rr'

class CloudSearchOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    endpoint http://example.com
    log_level debug
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::CloudSearchOutput, tag).configure(conf)
  end

  def create_driver_no_write(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::CloudSearchOutput, tag) do
      def write(chunk)
        chunk.read
      end
    end.configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        endpoint http://example.com
        buffer_chunk_limit 5M
      ]
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        buffer_chunk_limit 1M
      ]
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
      access_key_id ackey
      secret_access_key seckey
    ]
    assert_equal 4.5*1024*1024, d.instance.buffer.buffer_chunk_limit
    assert_equal nil, d.instance.profile_name
    assert_equal 'ackey', d.instance.access_key_id
    assert_equal 'seckey', d.instance.secret_access_key

  end

  def test_credential_type_access_key

    d = create_driver_no_write %[
      endpoint http://example.com
      access_key_id ackey
      secret_access_key seckey
    ]
    d.run

    client = d.instance.instance_variable_get(:@client)
    credentials = client.config.credentials

    assert_instance_of(Aws::Credentials, credentials)
    assert_equal 'ackey', credentials.access_key_id
    assert_equal 'seckey', credentials.secret_access_key

  end

  def test_credential_type_profile_name

    mock(Aws::SharedCredentials).new(:profile_name => 'cfprof') {
      Aws::Credentials.new("ok", "this is shared credentials mock")
    }
    d = create_driver_no_write %[
      endpoint http://example.com
      profile_name cfprof
    ]
    d.run

    client = d.instance.instance_variable_get(:@client)
    credentials = client.config.credentials

    assert_equal 'ok', credentials.access_key_id

  end

  def test_format

    d = create_driver_no_write

    d.emit({'id' => 'y0234', 'type' => 'hoge'}) # ignore because type
    d.emit({'id' => 'x1234', 'type' => 'add', 'fields' => {'foo' => 1, 'bar' => 'a'}})
    d.emit({'id' => 'y2234', 'type' => 'delete'})
    d.emit({'type' => 'add'}) # ignore because id is not exists
    d.emit({'id' => 'x4234', 'type' => 'add'}) # ignore because fields is not exits
    d.emit({'id' => 'x5234', 'type' => 'add', 'fields' => {'foo' => 3, 'bar' => 'b'}})
    d.emit({'id' => 'x3234'}) # ignore because type is not exists
    d.emit({'id' => 'x6789', 'type' => 'add', 'fields' => {'foo' => 1, 'bar' => "foo\u0014bar"}})

    d.expect_format %[{"id":"x1234","type":"add","fields":{"foo":1,"bar":"a"}},]
    d.expect_format %[{"id":"y2234","type":"delete"},]
    d.expect_format %[{"id":"x5234","type":"add","fields":{"foo":3,"bar":"b"}},]
    d.expect_format %[{"id":"x6789","type":"add","fields":{"foo":1,"bar":"foo bar"}},]

    d.run

  end

  def test_write
    documents = [
      {'id' => 'x1234', 'type' => 'add', 'fields' => {'foo' => 1, 'bar' => 'a'}},
      {'id' => 'y2234', 'type' => 'delete'},
      {'id' => 'x5234', 'type' => 'add', 'fields' => {'foo' => 3, 'bar' => 'b'}},
    ]
    stub_client = Aws::CloudSearchDomain::Client.new(
      :endpoint => 'http://example.com',
      :stub_responses => true
    )
    mock(Aws::CloudSearchDomain::Client).new(:endpoint => 'http://example.com') {
      stub_client
    }
    mock( stub_client ).upload_documents(
      :content_type => "application/json",
      :documents    => documents.to_json,
    )
    d = create_driver
    documents.each { |document|
      d.emit( document )
    }
    d.run
  end
end
