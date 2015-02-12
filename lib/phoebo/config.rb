module Phoebo
  class Config
    autoload :Image, 'phoebo/config/image'
    autoload :ImageCommands, 'phoebo/config/image_commands'

    attr_accessor :images, :tasks

    # Loads config from file
    # @see Phoebo.configure()
    def self.new_from_file(file_path)
      begin
        @instance = nil
        Kernel.load file_path, true
        @instance

      rescue ::SyntaxError => e
        raise Phoebo::SyntaxError, e.message
      end
    end

    def self.new_from_block(block)
      @instance = self.new
      @instance.dsl_eval(block)
    end

    # Instance initialization
    def initialize
      @images = []
      @tasks = []
    end

    # Evaluate block within DSL context
    def dsl_eval(block)
      @dsl ||= DSL.new(self)
      @dsl.instance_eval(&block)
      self
    end

    # Private DSL
    class DSL
      def initialize(config)
        @config = config
      end

      def image(name, from, &block)
        @config.images << (img_instance = Image.new(name, from, block))
        img_instance
      end

      def task(name, image, *args)
        task = {
          name: name,
          image: image
        }

        task[:cmd] = args unless args.empty?
        @config.tasks << task
        task
      end
    end

  end
end