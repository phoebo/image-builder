require 'optparse'
require 'colorize'

module Phoebo
  class Application
    attr_accessor :stdout, :stderr

    def initialize(args = [])
      # Set current standard/error output
      @stdout = $stdout
      @stderr = $stderr

      @args = args
    end

    def run
      result = 0
      options = parse_options

      if options[:error]
        result = 1
        @stderr.puts 'Error: '.red + options[:error]
        @stderr.puts
      end

      result |= send(('run_' + options[:mode].to_s).to_sym, options).to_i
      stdout.puts
      result
    end

    private

    def run_normal(options)
      # TODO
      fail IOError, 'File ' + options[:files].first.cyan + ' not found'
    end

    def run_help(_options)
      stdout.puts @option_parser
    end

    def run_version(_options)
      stdout.puts 'Version: #{Phoebo::VERSION}'
    end

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
