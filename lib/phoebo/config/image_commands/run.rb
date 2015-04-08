module Phoebo::Config::ImageCommands
  class Run
  	def self.id
  		:run
  	end

  	def self.action(cmd, *args)
      return Proc.new do |build|
        # TODO: decide which exec method we will use and enforce escaping
        build << "RUN #{cmd} #{args.join(' ')}"
      end
  	end
  end
end