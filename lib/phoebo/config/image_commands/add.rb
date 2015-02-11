module Phoebo::Config::ImageCommands
  class Add
  	def self.id
  		:add
  	end

  	def self.action(src, dest)
      return Proc.new do |dockerfile, files|

        virtual = 'project/' + src
        files[virtual] = src

        dockerfile << 'ADD ' + virtual + ' ' + dest
      end
  	end
  end
end