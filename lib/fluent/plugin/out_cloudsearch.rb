module Fluent
  class CloudSearchOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('cloudsearch', self)

    config_param :endpoint, :string
    config_param :region, :string, :default => "ap-northeast-1"

    # credentials by opt
    config_param :access_key_id, :string, :default => nil, :secret => true
    config_param :secret_access_key, :string, :default => nil, :secret => true

    # credentials by profile
    config_param :profile_name, :string, :default => nil

    # message packをJSONにした時に5MBを超えないように
    MAX_SIZE_LIMIT = 4.5*1024*1024

    def initialize
      super

      require 'aws-sdk'
    end

    def configure(conf)
      super

      if not @buffer_chunk_limit or @buffer_chunk_limit > MAX_SIZE_LIMIT
        @buffer_chunk_limit = MAX_SIZE_LIMIT
      end

      @formatter = Plugin.new_formatter('json')
    end

    def start
      super
      options = setup_credentials
      options[:endpoint] = @endpoint if @endpoint
      options[:region] = @region if @region
      @client = Aws::CloudSearchDomain::Client.new(options)
    end

    def shutdown
      super

    end

    def format(tag, time, record)
      @formatter.format_record(record)
    end

    def write(chunk)
      documents = '['
      documents << chunk.read.split("\n").join(",")
      documents << ']'
      resp = @client.upload_documents(
        :documents => documents,
        :content_type => "application/json"
      )
    end

    #http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudSearchDomain/Client.html#initialize-instance_method
    def setup_credentials
      options = {}
      if @access_key_id && @secret_access_key
        options[:credentials] = Aws::Credentials.new(@access_key_id, @secret_access_key)
      elsif @profile_name
        options[:credentials] = Aws::SharedCredentials.new(
          :profile_name => @profile_name
        )
      end
      options
    end
  end
end
