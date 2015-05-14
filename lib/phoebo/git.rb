module Phoebo
  class Git
    # Abstract implementation
    module Impl
      def available?
        true
      end
    end

    # Rugged implementation
    module RuggedImpl
      include Impl

      def clone(request, clone_path)
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

    # Missing (dummy) implementation
    module MissingImpl
      def available?
        false
      end

      RuggedImpl.public_instance_methods(false).each do |method_sym|
        define_method(method_sym) do |*args|
          raise "No Git implementation available. Install Rugged gem by `gem install rugged`."
        end
      end
    end
  end
end

# Extend Git by actual implementation
begin
  require 'rugged'
  Phoebo::Git.extend(Phoebo::Git::RuggedImpl)
rescue LoadError
  Phoebo::Git.extend(Phoebo::Git::MissingImpl)
end
