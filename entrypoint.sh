#!/usb/bin/env bash
set -e

log() {
  echo ">> [local]" "$@"
}

cleanup() {
  set +e
  log "Killing ssh agent."
  ssh-agent -k
  log "Removing workspace archive."
  rm -f /tmp/workspace.tar.bz2
}
trap cleanup EXIT

log "Packing workspace into archive to transfer onto remote machine."
tar cjvf /tmp/workspace.tar.bz2 "$TAR_PACKAGE_OPERATION_MODIFIERS" .

log "Launching ssh agent."
eval ssh-agent -s

ssh-add <(echo "$SSH_PRIVATE_KEY" | base64 -d)

remote_command="set -e;

log() {
    echo '>> [remote]' \$@ ;
};

log 'Creating workspace directory...';
mkdir \$workdir;

log 'Unpacking workspace...';
tar -C \$workdir -xjv;

log 'Launching docker-compose...';
cd \$workdir;

if $DOCKER_COMPOSE_DOWN
then
  log 'Executing docker-compose down...';
  docker-compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" down
else

if $NO_CACHE
  then
    docker-compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" build --no-cache
    docker-compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" up -d --remove-orphans --force-recreate
  else
    docker-compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" up -d --remove-orphans --build;
  fi
fi"

log "Connecting to remote host."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=100 \
  "$SSH_USER@$SSH_HOST" -p "$SSH_PORT" \
  "$remote_command" \
  < /tmp/workspace.tar.bz2