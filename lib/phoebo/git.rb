require 'rugged'

module Phoebo
  class Git
    def self.clone(request, clone_path)
      # Use passed SSH keys or fallback to system authentication
      if request.ssh_private_file
        cred = Rugged::Credentials::SshKey.new(
          username: request.ssh_user,
          publickey: request.ssh_public_file,
          privatekey: request.ssh_private_file
        )
      else
        cred = Rugged::Credentials::Default.new
      end

      # Clone remote repository
      begin
        Rugged::Repository.clone_at request.repo_url,
          clone_path, credentials: cred

      rescue Rugged::SshError => e
        raise unless e.message.include?('authentication')
        raise IOError, "Unable to clone remote repository. SSH authentication failed."
      end
    end
  end
end