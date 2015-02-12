require 'rubygems/package'
require 'docker'
require 'colorize'

module Phoebo
  module Docker
    class ImageBuilder
      include Console

      def initialize(base_path)
        @base_path = Pathname.new(base_path)
      end

      def build(image)
        project_files = { }
        dockerfile = []
        dockerfile << "FROM #{image.from}"

        # Apply all defined actions
        image.actions.each do |action|
          action.call(dockerfile, project_files)
        end

        # TODO: Honor file mode
        tar_stream = StringIO.new
        Gem::Package::TarWriter.new(tar_stream) do |tar|
          tar.add_file('Dockerfile', 0640) { |out_stream| out_stream.write(dockerfile.join("\n")) }
          tar.mkdir('project', 0750)

          # Copy project file into virtual destination
          while !project_files.empty? do
            virtual, relative = project_files.shift
            real = @base_path + relative

            if real.directory?
              real.each_entry do |child|
                next if child.fnmatch?('..') or child.fnmatch?('.')
                if child.directory?
                  tar.mkdir("#{virtual}/#{child}", 0750)
                end

                # Add to stack
                project_files["#{virtual}/#{child}"] = "#{relative}/#{child}"
              end

            elsif real.file?

              # 'file.txt' -> 'dest/'
              if virtual.end_with?('/')
                dest += real.basename.to_s
              end

              # Read file to our TAR output stream
              tar.add_file(virtual, 0640) do |out_stream|
                in_stream = real.open('r')
                IO.copy_stream(in_stream, out_stream)
              end
            end
          end
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

          stdout.puts "Tagging image #{built_image.id.to_s.cyan} -> #{image.name.cyan}"
          built_image.tag('repo' => image.name, 'force' => true)

          # Return image ID
          built_image.id

        rescue ::Docker::Error::UnexpectedResponseError => e
          raise DockerError, e.message
        end
      end
    end
  end
end