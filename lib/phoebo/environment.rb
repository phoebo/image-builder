# Provides layer for accessing external environment
class Phoebo::Environment

  # Reader definition macro
  def self.exe_path_reader(name, bin = nil)
    define_method("#{name}_path".to_sym) do
      if instance_variable_defined? "@#{name}"
        instance_variable_get "@#{name}"
      else
        instance_variable_set "@#{name}", path = exe_lookup(bin || name)
        path
      end
    end
  end

  # Path to executables
  # Example: exe_path_reader :our_bin, 'binary-name-to-lookup'
  #   -> Environment.our_bin_path
  exe_path_reader :git
  exe_path_reader :bash
  exe_path_reader :ssh_agent,   'ssh-agent'
  exe_path_reader :ssh_add,     'ssh-add'

  # Constructor
  def initialize(env = ENV)
    @env = env
  end

  # Temporary files
  def temp_path
    "#{File::SEPARATOR}tmp"
  end

  private

  # Look up executable in system path ($PATH)
  def exe_lookup(bin)
    if @system_path || @env['PATH']
      @system_path ||= @env['PATH'].encode(
        'UTF-8', 'binary',
        invalid: :replace,
        undef: :replace,
        replace: ''
      ).split(File::PATH_SEPARATOR)

      @system_path.each do |path|
        file_path = "#{path}#{File::SEPARATOR}#{bin}"
        return file_path if File.executable? file_path
      end

      nil
    end
  end
end

