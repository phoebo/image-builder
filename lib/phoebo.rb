require 'phoebo/version'

module Phoebo
  autoload :Application, 'phoebo/application'
  autoload :Console,     'phoebo/console'
  autoload :Environment, 'phoebo/environment'
  autoload :Util,        'phoebo/util'

  class PhoeboError < StandardError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class IOError < PhoeboError; status_code(4) ; end
  class ExternalError < PhoeboError; status_code(5) ; end
end
