module Phoebo
  module Docker
    autoload :ImageBuilder, 'phoebo/docker/image_builder'
    autoload :ImagePusher, 'phoebo/docker/image_pusher'

    # Writes stripped streamed response to output stream
    def self.process_output_stream(out, text)
      if m = text.match(/^{"stream"\:"(.+?)\\n?"}/)
        out.puts m[1].gsub(/\\u[0-9a-f]{4}/, '').light_black
      end
    end
  end
end