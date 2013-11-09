require_relative 'tools'


module RUPNP

  class Base
    include EM::Deferrable
    include Tools
    include LogMixin

    HTTP_COMMON_CONFIG = {
      :head => {
        :user_agent => USER_AGENT,
        :host => "#{HOST_IP}:#{DISCOVERY_PORT}",
      },
    }

    def initialize
      @parser = Nori.new(:convert_tags_to => ->(tag){ tag.snakecase.to_sym })
    end

    def get_description(location, getter)
      log :info, "getting description for #{location}"
      http = EM::HttpRequest.new(location).get(HTTP_COMMON_CONFIG)

      http.errback do |error|
        getter.set_deffered_status :failed, 'Cannot get description'
      end

      callback = Proc.new do
        description = @parser.parse(http.response)
        log :debug, 'Description received'
        getter.succeed description
      end

      http.headers do |h|
        unless h['SERVER'] =~ /UPnP\/1\.\d/
          log :error, "Not a supported UPnP response : #{h['SERVER']}"
          http.cancel_callback callback
        end
      end

      http.callback &callback
    end

  end

end
