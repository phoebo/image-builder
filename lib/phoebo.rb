require 'phoebo/version'

module Phoebo
  autoload :Application,        'phoebo/application'
  autoload :Config,             'phoebo/config'
  autoload :Console,            'phoebo/console'
  autoload :Docker,             'phoebo/docker'
  autoload :Environment,        'phoebo/environment'
  autoload :Git,                'phoebo/git'
  autoload :Request,            'phoebo/request'
  autoload :Util,               'phoebo/util'
  autoload :Worker,             'phoebo/worker'

  class PhoeboError < StandardError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class InvalidArgumentError < PhoeboError; status_code(4) ; end
  class InvalidRequestError < InvalidArgumentError ; end
  class IOError < PhoeboError; status_code(5) ; end
  class ExternalError < PhoeboError; status_code(6) ; end

  # Phoebofile errors
  class ConfigError < PhoeboError; status_code(7) ; end
  class SyntaxError < ConfigError; end

  # Error while generating Docker image
  class DockerError < PhoeboError; status_code(8) ; end

  # Configure Phoebo environment from Phoebofile
  def self.configure(version, &block)
    raise ConfigError, "Configuration version #{version} not supported" if version != 1
    Config.new_from_block(block)
  end

end
