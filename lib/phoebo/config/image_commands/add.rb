module Phoebo::Config::ImageCommands
  class Add
  	def self.id
  		:add
  	end

  	def self.action(src, dest)
      return Proc.new do |build|
        build.copy(build.base_path + src, dest)
      end
  	end
  end
end