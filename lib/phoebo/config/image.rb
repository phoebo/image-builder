module Phoebo
  class Config
    class Image
      attr_accessor :actions, :name, :from

      def initialize(name, options, block = nil)
        @actions = []
        @name = name

        if options.is_a?(Hash)

          # image('my-image', from: 'base-image')
          if options[:from]
            @from = [ :image, options[:from] ]
            raise Phoebo::SyntaxError.new('You can only use from: or from_dockerfile: directive as a base for your images.') if options[:from_dockerfile]

          # image('my-image', from_dockerfile: 'Dockerfile')
          elsif
            @from = [ :dockerfile, options[:from_dockerfile] ]
            raise Phoebo::SyntaxError.new('Building from Dockerfile is not supported yet.')
          end

        # Support for image('my-image', 'base-image')
        else
          @from = [ :base_image, options ]
        end

        unless @from
          raise Phoebo::SyntaxError.new('You need to specify base for your image (use from: or from_dockerfile:).')
        end

        dsl_eval(block) if block
      end

      # Evaluate block within DSL context
      def dsl_eval(block)
        @dsl ||= DSL.new(self)
        @dsl.instance_eval(&block)
        self
      end

      # Private DSL
      class DSL
        def initialize(image)
          @image = image
        end

        # Define action methods for all commands
        ImageCommands.commands.each do |id, command_class|
          define_method(id) do |*args|
            @image.actions << command_class.send(:action, *args)
          end
        end
      end

    end
  end
end