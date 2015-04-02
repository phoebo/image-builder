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

      # Finish config
      @tasks.each do |task|
        unless task[:image]
          if @images.size == 1
            task[:image] = @images.first.name
          else
            id = task[:service] ? "service #{task[:name]}" : "task #{task[:name]}"
            raise Phoebo::SyntaxError.new("You need to define image for #{id}.")
          end
        end
      end

      self
    end

    # Private DSL
    class DSL
      def initialize(config)
        @config = config
      end

      def image(name, options, &block)
        @config.images << (img_instance = Image.new(name, options, block))
        img_instance
      end

      def service(name, options = {})
        _task_definition_check('service', name, options)

        task = {
          name: name.to_s,
          service: true
        }

        _apply_task_options(task, options)

        if options[:ports]
          if options[:ports].is_a?(Array)
            task[:ports] = options[:ports].collect do |port_def|
              if port_def.is_a?(Hash) && port_def.size == 1
                { port_def.keys.first.to_sym => port_def.values.first.to_i }
              else
                raise Phoebo::SyntaxError.new("Expected port definition in form { tcp: 1234 } for service #{name}")
              end
            end
          else
            raise Phoebo::SyntaxError.new("Expected Array for ports definition of service #{name}.")
          end

          options.delete(:ports)
        end

        unless options.empty?
          raise Phoebo::SyntaxError.new("Unexpected parameter #{options.keys.first} for service #{name}.")
        end

        puts task.inspect

        @config.tasks << task
        task
      end

      def task(name, image, *args)
        _task_definition_check('service', name, options)

        task = {
          name: name.to_s
        }

        _apply_task_options(task, options)

        unless options.empty?
          raise Phoebo::SyntaxError.new("Unexpected parameter #{options.keys.first} for task #{name}.")
        end

        @config.tasks << task
        task
      end

      private

      def _task_definition_check(subject, name, options)
        raise Phoebo::SyntaxError.new("Name required for #{subject} definition.") if name.to_s.empty?
        raise Phoebo::SyntaxError.new("Unexpected block for #{subject} #{name}.") if block_given?
        raise Phoebo::SyntaxError.new("Unexpected parameters for #{subject} #{name}. Expected Hash.") unless options.is_a?(Hash)
      end

      def _apply_task_options(task, options)
        if options[:image]
          task[:image] = options[:image].to_s
          options.delete(:image)
        end

        if options[:command]
          task[:command] = options[:command].to_s
          options.delete(:command)
        end

        if options[:arguments]
          if options[:arguments].is_a?(Array)
            task[:arguments] = options[:arguments].collect { |item| item.to_s }
          else
            task[:arguments] = [ options[:arguments].to_s ]
          end

          options.delete(:arguments)
        end
      end
    end
  end
end