module Phoebo
  module Docker
    class ImagePusher
      include Console

      def initialize(username, password, email)
        @username = username
        @password = password
        @email = email
      end

      def push(image_id)
        unless @authenticated
          @authenticated = true
          stdout.puts "Authenticating " + "...".light_black
          begin
            ::Docker.authenticate!({'username' => @username, 'password' => @password, 'email' => @email}, ::Docker.connection)
          rescue ::Docker::Error::AuthenticationError => e
            raise DockerError, 'Authentication to docker registry failed.'
          end
        end

        stdout.puts "Pushing image " + image_id.cyan + " ...".light_black

        built_image = ::Docker::Image.get(image_id)
        built_image.push
      end
    end
  end
end