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
    MAX_SIZE_LIMIT = 4.5 * 1024 * 1024

    # https://docs.aws.amazon.com/en_us/cloudsearch/latest/developerguide/preparing-data.html
    INVALID_CHAR_REGEX = /[^\u0009\u000a\u000d\u0020-\uD7FF\uE000-\uFFFD]/

    def initialize
      super

      require 'aws-sdk'
      require 'json'
    end

    def configure(conf)

      # override config. (config_set_default can't override it)
      conf['buffer_chunk_limit'] ||= MAX_SIZE_LIMIT

      super

      unless @endpoint
        raise ConfigError, "'endpoint' parameter is required"
      end
      if @buffer.buffer_chunk_limit > MAX_SIZE_LIMIT
        raise ConfigError, "buffer_chunk_limit must be less than #{MAX_SIZE_LIMIT}"
      end
    end

    def start
      super
      options = setup_credentials
      options[:endpoint] = @endpoint
      options[:region] = @region if @region
      @client = Aws::CloudSearchDomain::Client.new(options)
    end

    def shutdown
      super

    end

    def format(tag, time, record)
      if !record.key?('id') then
        log.warn "id is required #{record.to_s}"
        return ''
      elsif !record.key?('type') then
        log.warn "type is required #{record.to_s}"
        return ''
      elsif record['type'] == 'add' then
        if !record.key?('fields') then
            log.warn "fields is required when type is add. #{record.to_s}"
            return ''
        end
      elsif record['type'] != 'delete' then
        log.warn "type is add or delete #{record.to_s}"
        return ''
      end

      r = record.dup
      f = r['fields']
      if f.kind_of? Hash
        # replace invalid char to white space
        f.each do |key, value|
          if value.kind_of? String
            f[key] = value.gsub(INVALID_CHAR_REGEX, ' ')
          else
            f[key] = value
          end
        end
      end

      return "#{r.to_json},"
    end

    def write(chunk)
      documents = '['
      documents << chunk.read.chop  # chop last ','
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
