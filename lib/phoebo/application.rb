require 'optparse'
require 'colorize'
require 'pathname'

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

      [send(('run_' + options[:mode].to_s).to_sym, options).to_i, result].max
    end

    # Cleanup sequence
    def cleanup
      if @temp_file_manager && @temp_file_manager.need_cleanup?
        stdout.puts "Cleaning up"
        stdout.puts
        @temp_file_manager.cleanup
      end
    end

    private

    # Run in normal mode
    def run_normal(options)

      request = Request.new
      request.load_from_hash!(options[:request])

      if options[:request_file]
        stdout.puts "Loading request from file: " + options[:request_file].cyan
        request.load_from_file!(options[:request_file])
      end

      if options[:request_url]
        stdout.puts "Fetching request from URL: " + options[:request_url].cyan + "...".light_black
        request.load_from_url!(options[:request_url])
      end

      # Raises InvalidRequestError if invalid
      request.validate

      # Prepare project directory
      if request.repo_url
        # Create temp dir & clone
        project_path = temp_file_manager.path('project')
        stdout.puts "Cloning remote repository " + "...".light_black
        Git.clone(request, project_path)

      else
        project_path = Dir.pwd
      end

      # Worker
      worker = Worker.new(request)
      result = 0

      # Process all
      options[:files] << '.' if options[:files].empty?
      options[:files].each do |rel_path|
        path = (Pathname.new(project_path) + rel_path)

        # Directory does not exist -> resume with next dir.
        if path.exist?
          path = path.realpath.to_s
        else
          stderr.puts "Directory #{path.to_s} does not exist".red
          result = 1
          next
        end

        # Directory does not have any config -> nothing to do -> resume with next dir.
        unless worker.process(path)
          stderr.puts "No config found in #{path}".red
          result = 1
          next
        end
      end

      stdout.puts "Everything done :-)".green
      result
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
      options = { error: nil, mode: :normal, request: {}, files: [], ssh_user: 'git' }

      unless @option_parser
        @option_parser = OptionParser.new
        @option_parser.banner = \
          "Usage: #{@option_parser.program_name} [options] file"

        @option_parser.on_tail('-rURL', '--repository=URL', 'Repository URL') do |value|
          options[:request][:repo_url] = value
        end

        @option_parser.on_tail('--ssh-user=USERNAME', 'Username for Git over SSH (Default: git)') do |value|
          options[:request][:ssh_user] = value
        end

        @option_parser.on_tail('--ssh-public=PATH', 'Path to public SSH key for Git repository') do |value|
          options[:request][:ssh_public_file] = value
        end

        @option_parser.on_tail('--ssh-key=PATH', 'Path to SSH key for Git repository') do |value|
          options[:request][:ssh_private_file] = value
        end

        @option_parser.on_tail('--docker-user=USERNAME', 'Username for Docker Registry') do |value|
          options[:request][:docker_user] = value
        end

        @option_parser.on_tail('--docker-password=PASSWORD', 'Password for Docker Registry') do |value|
          options[:request][:docker_password] = value
        end

        @option_parser.on_tail('--docker-email=EMAIL', 'E-mail for Docker Registry') do |value|
          options[:request][:docker_email] = value
        end

        @option_parser.on_tail('-U', '--from-url=REQUEST_URL', 'Process build request from URL') do |value|
          options[:request_url] = value
        end

        @option_parser.on_tail('-f', '--from-file=PATH', 'Process build request from local file') do |value|
          options[:request_file] = value
        end

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

