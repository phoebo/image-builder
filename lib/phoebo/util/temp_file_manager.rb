require 'fileutils'

# Temporary File Manager
#
# - Creates temporary directory exclusive for our process
# - Cleans up
#
class Phoebo::Util::TempFileManager

  def initialize(temp_path)
    @base_path = temp_path
  end

  def path(*components)
    unless @process_path
      @process_path = "#{@base_path}#{File::SEPARATOR}phoebo-#{Process.pid}"
      FileUtils::mkdir_p @process_path
      FileUtils::chmod 0600, @process_path
    end

    File.join(@process_path, components)
  end

  def need_cleanup?
    @process_path != nil && File.exist?(@process_path)
  end

  def cleanup
    if @process_path
      FileUtils.remove_dir @process_path
      @process_path = nil
    end
  end

end