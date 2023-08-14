## docker-compose-ssh-deployment
This GitHub actions deploys a repository with docker-compose via SSH to a remote host.

This action packs contents of the action workspace into an archive.
It then proceeds to log into the remote host via SSH and unpacks the workspace there.

Finally, it runs `docker-compose up -d` on the remote host with the provided arguments.

Comparing to other actions with similar behavior this one does not use any
unknown docker-images. It is entirely built from Dockerfile on top of
`alpine:3.10`.

## Inputs

* `ssh_private_key` - The SSH private key used for logging into remote system.
* `ssh_host` - The remote host name or IP address.
* `ssh_port` - The remote port number. Default: `22`.
* `ssh_user` - The remote username. Default: `docker-deploy`.
* `docker_compose_prefix` - A prefix to add to the deployed containers.
* `docker_compose_filename` - The docker-compose file name. Default: `docker-compose.yaml`.
* `use_stack` - Use docker stack instead of docker-compose.
* `no_cache` - Adds --no-cache flag to docker build command.
* `tar_package_operation_modifiers` - Tar operation modifiers used while creating the package.
* `docker_compose_down` - Execute docker-compose down before docker-compose up.
* `dockerhub_username` - Username for dockerhub login.
* `dockerhub_password` - Password for dockerhub login.

# Example usage

Let's say you have a repo with single docker-compose file in it and a remote server with docker and docker-compose installed.

1. Generate key pair, do not use a password here.
    
    ```sh
    ssh-keygen -t ed25519 -f deploy_key
    ```

2. Create a user which will deploy containers for you on the remote server, do
   not set password for this user:

    ```sh
    $ sudo useradd -m -b /var/lib -G docker docker-deploy
    ```

3. Allow to log into that user with the key you generated on the step one.

    ```sh
    $ sudo mkdir /var/lib/docker-deploy/.ssh
   
    # Set the owner of the .ssh directory to the docker-deploy user
    $ sudo chown docker-deploy:docker-deploy /var/lib/docker-deploy/.ssh
   
    # Add the public key to the authorized_keys file 
    $ sudo install -o docker-deploy -g docker-deploy -m 0600 deploy_key.pub /var/lib/docker-deploy/.ssh/authorized_keys
   
    # Restrict access to the .ssh directory
    $ sudo chmod 0500 /var/lib/docker-deploy/.ssh
    $ rm deploy_key.pub
    ```

4. Test that key works.

    ```sh
    ssh -i deploy_key docker-deploy@<your-remote-server.com>
    ```

5. Add private key and username into secrets for the repository. Let's say that
   names of the secrets are `SSH_PRIVATE_KEY` and
   `SSH_USER`.

6. Remove your local copy of the ssh key:

    ```sh
    rm deploy_key
    ```

7. Set up a GitHub actions workflow (e.g. `.github/workflows/main.yml`):

    ```yaml
    name: Remote Deployment
    on:
      push:
        branches: [ "main" ]
    jobs:
      deploy:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2
    
        - uses: masterjanic/docker-compose-ssh-deployment@master
          name: Docker-Compose Remote Deployment
          with:
            ssh_host: your-remote-server.com
            ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
            ssh_user: ${{ secrets.SSH_USER }}
    ```

8. You're all set!

# Swarm & Stack

In case you want to use some more advanced features like secrets. You'll need to
set up a docker swarm cluster and use docker stack command instead of the plain
docker-compose. To do that just set `use_stack` input to `"true"`:

```yaml
name: Remote Deployment
on:
  push:
    branches: [ "main" ]
jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    
    - uses: masterjanic/docker-compose-ssh-deployment@master
      name: Docker-Stack Remote Deployment
      with:
        ssh_host: your-remote-server.com
        ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
        ssh_user: ${{ secrets.SSH_USER }}
        use_stack: 'true'
```
