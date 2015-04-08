module Phoebo::Config::ImageCommands
  class Create
    def self.id
      :create
    end

    def self.action(destination, content = nil, &block)
      return Proc.new do |build|
        if block
          build.create(destination, &block)
        else
          build.create(destination) do |out_stream|
            out_stream.write(content)
          end
        end
      end
    end
  end
end