module Phoebo
  class Worker
    def initialize(request)
      @request = request
    end

    def pusher
      @pusher ||= Docker::ImagePusher.new(
        @request.docker_user,
        @request.docker_password,
        @request.docker_email
      )
    end

    def process(path)

      # Prepare config path
      config_filename = 'Phoebofile'
      config_path = "#{path}#{File::SEPARATOR}#{config_filename}"

      if File.exists?(config_path)
        # Load config
        config = Config.new_from_file(config_path, @request)

        # Build & push image
        builder = Docker::ImageBuilder.new(path, @request)
        config.images.each do |image|
          image_id = builder.build(image)
          pusher.push(image_id) if @request.docker_user
        end

        config
      else
        false
      end
    end
  end
end