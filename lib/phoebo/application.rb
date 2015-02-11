require 'optparse'
require 'colorize'
require 'docker'
require 'rugged'

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
      if @temp_file_manager && @temp_file_manager.need_cleanup?
        stdout.puts "Cleaning up"
        stdout.puts
        @temp_file_manager.cleanup
      end
    end

    private

    # Run in normal mode
    def run_normal(options)

      # Default project path, is PWD
      project_path = Dir.pwd

      # If we are building image from Git repository
      if options[:repository]

        # Prepare SSH credentials if necessary
        if options[:ssh_key]
          private_path = Pathname.new(options[:ssh_key])

          raise InvalidArgumentError, "SSH key not found" unless private_path.exist?
          raise InvalidArgumentError, "Missing public SSH key" unless options[:ssh_public]

          public_path = Pathname.new(options[:ssh_public])
          raise InvalidArgumentError, "Public SSH key not found" unless public_path.exist?

          cred = Rugged::Credentials::SshKey.new(
            username: options[:ssh_user],
            publickey: public_path.realpath.to_s,
            privatekey: private_path.realpath.to_s
          )
        else
          cred = nil
        end

        # Create temp dir.
        project_path = temp_file_manager.path('project')

        # Clone remote repository
        begin
          stdout.puts "Cloning remote repository " + "...".light_black
          Rugged::Repository.clone_at options[:repository],
            project_path, credentials: cred

        rescue Rugged::SshError => e
          raise unless e.message.include?('authentication')
          raise IOError, "Unable to clone remote repository. SSH authentication failed."
        end
      end

      # Prepare Docker credentials
      if options[:docker_username]
        raise InvalidArgumentError, "Missing docker password." unless options[:docker_password]
        raise InvalidArgumentError, "Missing docker e-mail." unless options[:docker_email]

        pusher = Docker::ImagePusher.new(
          options[:docker_username],
          options[:docker_password],
          options[:docker_email]
        )
      else
        pusher = nil
      end

      # Exit code
      result = 0

      # Process all the files
      options[:files] << '.' if options[:files].empty?
      options[:files].each do |rel_path|

        path = (Pathname.new(project_path) + rel_path).realpath.to_s

        # Prepare config path
        config_filename = 'Phoebofile'
        config_path = "#{path}#{File::SEPARATOR}#{config_filename}"

        # Check if config exists -> resumable error
        unless File.exists?(config_path)
          stderr.puts "No #{config_filename} found in #{path}".red
          result = 1
          next
        end

        # Load config
        config = Config.load_from_file(config_path)

        # Build & push image
        builder = Docker::ImageBuilder.new(path)
        config.images.each do |image|
          image_id = builder.build(image)
          pusher.push(image_id) if pusher
        end
      end

      puts "Everything done :-)".green

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
      options = { error: nil, mode: :normal, files: [], ssh_user: 'git' }

      unless @option_parser
        @option_parser = OptionParser.new
        @option_parser.banner = \
          "Usage: #{@option_parser.program_name} [options] file"

        @option_parser.on_tail('-rURL', '--repository=URL', 'Repository URL') do |value|
          options[:repository] = value
        end

        @option_parser.on_tail('--ssh-user=USERNAME', 'Username for Git over SSH (Default: git)') do |value|
          options[:ssh_user] = value
        end

        @option_parser.on_tail('--ssh-public=PATH', 'Path to public SSH key for Git repository') do |value|
          options[:ssh_public] = value
        end

        @option_parser.on_tail('--ssh-key=PATH', 'Path to SSH key for Git repository') do |value|
          options[:ssh_key] = value
        end

        @option_parser.on_tail('--docker-user=USERNAME', 'Username for Docker Registry') do |value|
          options[:docker_username] = value
        end

        @option_parser.on_tail('--docker-password=PASSWORD', 'Password for Docker Registry') do |value|
          options[:docker_password] = value
        end

        @option_parser.on_tail('--docker-email=EMAIL', 'E-mail for Docker Registry') do |value|
          options[:docker_email] = value
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

