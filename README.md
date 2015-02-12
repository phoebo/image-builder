# Phoebo

## DSL example

~~~
Phoebo.configure(1) {

  # Create image based on Apache + mod_php
  image('phoebo/nette-example', 'phoebo/simple-apache-php') {
    # Copy all application data
    add('.', '/app/')

    # Install dependencies
    run('composer', 'install', '--prefer-dist')

    # Set document root
    run('ln', '-s', '/app/www', '/var/www')
  }

  # Deploy image and keep it runing (default CMD: apache)
  task('deploy', 'phoebo/nette-example')

  # Run tests on image
  task('test', 'phoebo/nette-example', '/app/bin/tester', '/app/tests')
}
~~~

## Usage

~~~
sudo docker pull phoebo/phoebo:latest
sudo docker run -ti --privileged -v ~/nette-example-keys:/root/deploy-keys phoebo/phoebo:latest phoebo \
   --repository ssh://gitlab.fit.cvut.cz/phoebo/nette-example.git \
   --ssh-key /root/deploy-keys/key \
   --ssh-public /root/deploy-keys/key.pub \
   --docker-user joe \
   --docker-password secret123 \
   --docker-email joe@domain.tld
~~~

### Process request from URL

For better integration into your CI workflow you can specify build job by URL instead of verbose CLI arguments.

~~~
phoebo --from-url http://domain.tld/api/requests/2e2996fe8420
~~~

URL should return JSON formatted payload with following structure:

~~~
{
	"id": "2e2996fe8420",
	"repo_url": "ssh://gitlab.fit.cvut.cz/phoebo/nette-example.git",
	"ssh_public": "ssh-rsa AAAAB3NzaC1yc2E...",
	"ssh_private": "-----BEGIN RSA PRIVATE KEY----- ...",
	"docker_user": "joe",
	"docker_password": "secret123",
	"docker_email": "joe@domain.tld"
}
~~~

If other CLI arguments are present they will override those loaded from URL.

### Ping back

You can optionally let Phoebo notify you when the build is ready.

~~~
phoebo --ping-url http://domain.tld/api/notify
~~~

Notification is sent as JSON formatted HTTP POST request with structure bellow.
The payload contains the same ID you've passed to application with your JSON request.
Other than that payload contains list of tasks with arguments and image on which they should be run.

~~~
{
   "id": "2e2996fe8420",
   "tasks":[
      {
         "name":"deploy",
         "image":"phoebo/nette-example"
      },
      {
         "name":"test",
         "image":"phoebo/nette-example",
         "cmd":[
            "/app/bin/tester",
            "/app/tests"
         ]
      }
   ]
}
~~~
