require 'phoebo/version'

module Phoebo
  autoload :Application, 'phoebo/application'

  class PhoeboError < StandardError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class IOError < PhoeboError; status_code(4) ; end
end
