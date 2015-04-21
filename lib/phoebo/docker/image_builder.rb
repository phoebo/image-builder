require 'rubygems/package'
require 'docker'
require 'colorize'
require 'securerandom'

module Phoebo
  module Docker
    class ImageBuilder
      include Console

      def initialize(base_path)
        @base_path = Pathname.new(base_path)
      end

      def build(image, tag)
        project_files = { }
        dockerfile = []

        if image.from.first == :base_image
          dockerfile << "FROM #{image.from[1]}"
        end

        tar_stream = StringIO.new
        Gem::Package::TarWriter.new(tar_stream) do |tar|

          image_build = Build.new(@base_path, dockerfile, tar)

          # Apply all defined actions
          image.actions.each do |action|
            action.call(image_build)
          end

          # Create Dockerfile
          tar.add_file('Dockerfile', 0640) { |out_stream| out_stream.write(dockerfile.join("\n")) }
        end

        begin
          stdout.puts "Building image " + "...".light_black
          built_image = ::Docker::Image.build_from_tar(tar_stream.tap(&:rewind)) { |text|
            Docker.process_output_stream(stdout, text)
          }

          # TODO: Perhaps we should calculate size from virtual size of the base,
          # this is not working very well while merging layers.
          stdout.puts "Image build successful".green
          stdout.print "ID: " + built_image.id.to_s.cyan
          stdout.print " size: " + ('%.2f MB' % (built_image.json['Size'].to_f / 1000 / 1000)).cyan if built_image.json['Size'] > 100
          stdout.print " virtual size: " + ('%.2f MB' % (built_image.json['VirtualSize'].to_f / 1000 / 1000)).cyan
          stdout.puts

          stdout.puts "Tagging image #{built_image.id.to_s.cyan} -> #{image.name.cyan}#{':'.cyan}#{tag.cyan}"
          built_image.tag('repo' => image.name, 'tag' => tag, 'force' => true)

          # Return image ID
          built_image.id

        rescue ::Docker::Error::UnexpectedResponseError => e
          raise DockerError, e.message
        end
      end

      class Build
        attr_reader :base_path, :dockerfile, :tar

        def initialize(base_path, dockerfile, tar)
          @base_path = base_path
          @dockerfile = dockerfile
          @tar = tar

          @dirs = { }
        end

        # Add Dockerfile instruction
        def <<(str)
          @dockerfile << str
        end

        # Create new file by block
        def create(destination_path, mode = 640, &block)
          basename = Pathname.new(destination_path).basename.to_s
          random = random_dir

          # Add Dockerfile instruction
          virtual = "#{random}/#{basename}"
          self << 'ADD ' + virtual + ' ' + destination_path

          # Create directory for this instruction
          tar.mkdir(random, 750)

          # Add file with yielded block
          @tar.add_file(virtual, mode, &block)
        end

        # Copy files to docker image
        def copy(source, destination_path)
          # TODO: Honor file mode

          source = Pathname.new(source) unless source.is_a?(Pathname)
          random = random_dir

          # Add Dockerfile instruction
          if source.directory?
            self << 'ADD ' + random + ' ' + destination_path
            files = [ [ source, random ] ]
          else
            self << 'ADD ' + random + '/' + source.basename.to_s + ' ' + destination_path
            files = [ [ source, random + '/' ] ]
          end

          # Create directory for this instruction
          tar.mkdir(random, 750)

          # Add all the files recursively
          while !files.empty? do
            source, destination_path = files.shift

            # Directory
            if source.directory?
              source.each_entry do |child|
                next if child.fnmatch?('..') or child.fnmatch?('.')
                @tar.mkdir("#{destination_path}/#{child}", 0750) if child.directory?
                files << [ source + child, "#{destination_path}/#{child}" ]
              end

            # File
            elsif source.file?
              # If we are adding 'file.txt' to 'dest/': we need to append filename
              destination_path += source.basename.to_s if destination_path.end_with?('/')

              # Add file copy
              @tar.add_file(destination_path, 0640) do |out_stream|
                in_stream = source.open('r')
                IO.copy_stream(in_stream, out_stream)
              end
            end
          end
        end

        private

        def random_dir
          begin
            random = SecureRandom.hex
          end while @dirs.key?(random)

          @dirs[random] = true
          random
        end
      end
    end
  end
end