require 'uri'
require 'net/http'
require 'json'

module Phoebo
  # Application request
  # Class is used as a container for user input and to perform easy merging user
  # input from multiple sources (HTTP request, CLI options) and provides data
  # validation with human-readable error messages.
  class Request
    attr_accessor :repo_url, :ssh_user, :ssh_private_file, :ssh_public_file
    attr_accessor :docker_user, :docker_password, :docker_email
    attr_accessor :id, :ping_url
    attr_writer :temp_file_manager

    def initialize
      @ssh_user = 'git'
    end

    # Temporary file manager
    def temp_file_manager
      @temp_file_manager ||= Application.instance.temp_file_manager
    end

    # Allows to use SSH content instead of SSH key file
    # (We need to place it into temporary file because Rugged needs it)
    def ssh_private=(key_content)
      @ssh_private_file = temp_file_manager.path('key')
      IO.write(@ssh_private_file, key_content)
    end

    # Allows to use SSH content instead of SSH key file
    # (We need to place it into temporary file because Rugged needs it)
    def ssh_public=(key_content)
      @ssh_public_file = temp_file_manager.path('key.pub')
      IO.write(@ssh_public_file, key_content)
    end

    # Loads request with data from hash
    def load_from_hash!(hash)
      hash.each do |k, v|
        m = (k.to_s + '=').to_sym
        raise InvalidRequestError, "Invalid key #{k.inspect}" unless respond_to?(m)
        send(m, v)
      end

      self
    end

    # Loads request from JSON string
    def load_from_json!(raw_data)
      begin
        hash = JSON.parse(raw_data)
      rescue JSON::ParserError => e
        raise InvalidRequestError, "Malformed JSON data."
      end

      load_from_hash!(hash)
    end

    # Loads request fro local file
    def load_from_file!(file_path)
      raise IOError, "File #{file_path} not exist" unless File.exist?(file_path)
      raw_data = IO.read(file_path)
      load_from_json!(raw_data)
    end

    # Loads request from URL
    def load_from_url!(url)
      uri = URI(url)
      req = Net::HTTP::Get.new(uri)
      req['Accept'] = 'application/json'

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      # TODO: handle redirects
      raise IOError, "Unable to load URL #{url}" unless res.code == 200

      load_from_json!(res.body)
    end

    # Validates request and returns array of error messages
    # or empty array if there are none
    def errors
      errors = []

      if repo_url
        begin
          uri = URI(repo_url)
          errors << "Invalid repository URL. Only SSH supported at the moment. Expected format: ssh://host/path/to/repo.git" \
             unless uri.scheme == 'ssh'
        rescue URI::InvalidURIError
          errors << "Invalid repository URL. Expected format: ssh://host/path/to/repo.git"
        end
      end

      unless [ssh_private_file, ssh_public_file].select { |v| v } .empty?
        errors << "Missing SSH user." unless ssh_user
        errors << "Missing private SSH key." unless ssh_private_file
        errors << "Missing public SSH key." unless ssh_public_file
      end

      unless [docker_user, docker_password, docker_email].select { |v| v } .empty?
        errors << "Missing Docker user." unless docker_user
        errors << "Missing Docker password." unless docker_password
        errors << "Missing Docker email." unless docker_email
      end

      if ping_url
        begin
          uri = URI(ping_url)
          errors << "Invalid ping URL. Only HTTP / HTTPS supported at the moment. Expected format: https://domain.tld/api/notify" \
             unless uri.scheme == 'http' || uri.scheme == 'https'
        rescue URI::InvalidURIError
          errors << "Invalid ping URL. Expected format: https://domain.tld/api/notify"
        end
      end

      errors
    end

    # Validate request and raises first discovered error as an exception
    def validate
      unless (e = errors).empty?
        raise InvalidRequestError, e.first
      end
    end

  end
end