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
        repo = Rugged::Repository.clone_at request.repo_url,
          clone_path, credentials: cred

        if request.ref
          if request.ref =~ /^[0-9a-f]+$/i
            if repo.exists?(request.ref.downcase)
              repo.checkout(request.ref.downcase, strategy: :force)
            else
              raise IOError, "Unable to find commit #{request.ref}. Git checkout failed."
            end
          else
            raise IOError, "Invalid commit reference #{request.ref}. Git checkout failed."
          end
        end

      rescue Rugged::SshError => e
        raise unless e.message.include?('auth')
        raise IOError, "Unable to clone remote repository. SSH authentication failed."
      end
    end
  end
end