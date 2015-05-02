# Image Builder

This project is a component of Phoebo CI responsible for building Docker images.

## Local installation

### Requirements

- Docker

### Install as Gem

```bash
# Necessary libraries for working SSH authorization for Git (Rugged)
apt-get install cmake pkg-config libssh2-1-dev

# Install Rugged with previously installed system libraries
gem install rugged -- --use-system-libraries

# Install Phoebo Image Builder
gem install phoebo
```

## Use inside of Docker

### With shared Docker

```bash
docker run \
  -v /var/run/docker.sock:/tmp/docker.sock
  -e NO_DIND=1 -e DOCKER_URL=unix:///tmp/docker.sock \
  phoebo/image-builder:latest \
  phoebo --help
```

### DinD

```bash
docker run --privileged \
  phoebo/image-builder:latest \
  phoebo --help
```

## DSL example

~~~ruby
Phoebo.configure(1) {

  # Create image based on Apache + mod_php
  image('phoebo/nette-example', from: 'phoebo/simple-apache-php') {
    # Copy all application data
    add('.', '/app/')

    # Install dependencies
    run('composer', 'install', '--prefer-dist')

    # Set document root
    run('ln', '-s', '/app/www', '/var/www')
  }

  # Deploy image and start web server (default CMD: apache)
  service(’Web’,
    image: ’phoebo/nette-example’,
    ports: [
      { tcp: 80 }
    ]
  )
}
~~~

## Usage

~~~bash
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

~~~bash
phoebo --from-url http://domain.tld/api/requests/2e2996fe8420
~~~

URL should return JSON formatted payload with following structure:

~~~javascript
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

~~~bash
phoebo --ping-url http://domain.tld/api/notify
~~~

Notification is sent as JSON formatted HTTP POST request with structure bellow.
The payload contains the same ID you've passed to application with your JSON request.
Other than that payload contains list of tasks with arguments and image on which they should be run.

~~~javascript
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

## Contact

Project is developed by Adam Staněk <adam.stanek@v3net.cz>
