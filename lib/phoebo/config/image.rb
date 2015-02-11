module Phoebo
  class Config
    class Image
      attr_accessor :actions, :name, :from

      def initialize(name, from)
        @actions = []
        @name = name
        @from = from
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