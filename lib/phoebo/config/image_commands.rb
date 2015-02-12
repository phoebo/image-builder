# Auto-require
Dir[File.dirname(__FILE__) + '/image_commands/*.rb'].each { |file| require file }

# Module containing all Image commands
module Phoebo::Config::ImageCommands

	# Returns all discovered commands
	def self.commands
		unless @commands
			@commands = {}
			self.constants.each do |c|
				c = self.const_get(c)
				next unless Class === c
				@commands[c.id] = c
			end
		end

		@commands
	end
end