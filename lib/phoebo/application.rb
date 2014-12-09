require 'optparse'
require 'colorize'

module Phoebo
  #
  # Main Application
  #
  # Performs run sequence and holds instances of necessary services to ease
  # access without need of dependency injection. You should still allow to
  # pass dependency if necessary (for testing).
  # Use following snippet in your class:
  #
  # class MyClass
  #   attr_writer :environment
  #   def environment
  #     @environment ||= Application.instance.environment
  #   end
  # end
  #
  class Application
    include Console

    # Creates application
    def initialize(args = [])
      @args = args
      @@instance = self
    end

    # Returns last application instance
    def self.instance
      @@instance
    end

    # Environment service instance
    def environment
      @environment ||= Environment.new
    end

    # Temporary File Manager
    def temp_file_manager
      @temp_file_manager ||= Util::TempFileManager.new(environment.temp_path)
    end

    # Run sequence
    def run()
      result = 0
      options = parse_options

      if options[:error]
        result = 1
        stderr.puts 'Error: '.red + options[:error]
        stderr.puts
      end

      send(('run_' + options[:mode].to_s).to_sym, options).to_i || result
    end

    # Cleanup sequence
    def cleanup
      if @temp_file_manager && @temp_file_manager.needs_cleanup?
        stdout.puts "Cleaning up"
        stdout.puts
        @temp_file_manager.cleanup
      end
    end

    private

    # Run in normal mode
    def run_normal(options)
      fail IOError, 'File ' + options[:files].first.cyan + ' not found'
    end

    # Show help
    def run_help(_options)
      stdout.puts @option_parser
      stdout.puts
    end

    # Show version info
    def run_version(_options)
      stdout.puts "Version: #{Phoebo::VERSION}"
      stdout.puts
    end

    # Parse passed command-line options
    def parse_options
      options = { error: nil, mode: :normal, files: [] }

      unless @option_parser
        @option_parser = OptionParser.new
        @option_parser.banner = \
          'Usage: #{@option_parser.program_name} [options] file'

        @option_parser.on_tail('--version', 'Show version info') do
          options[:mode] = :version
        end

        @option_parser.on_tail('-h', '--help', 'Show this message') do
          options[:mode] = :help
        end
      end

      begin
        # Parse and go through all non-options
        @option_parser.parse(@args).each do |arg|
          options[:files] << arg
        end

      rescue OptionParser::ParseError => err
        options[:mode] = :help
        options[:error] = err.message
      end

      options
    end
  end
end

