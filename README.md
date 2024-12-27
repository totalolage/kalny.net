# kalny.net services

This is a collection of services that I've built and deployed on my own servers.

## Services

All services are deployed using Docker Stack and accessible via the reverse proxy. To deploy a service, first set the docer context to the deployment target:

```sh
docker context use kalny.net
```

If you do not have the context set, you can set it with:

```sh
docker context create kalny.net --docker "host=ssh://admin@kalny.net"
```

(make sure that you have your ssh keys set up on the kalny.net server)

### Traefik

Manages the reverse proxy for all other services.

To deploy:

```sh
traefik/deploy.sh
```

*Note:* The deploy script is needed instead of invoking `docker stack deploy` or `docker stack update` directly because it handles reloading configurations for the service, which might change between deploys.*

The service dashboard is available at [https://traefik.kalny.net/dashboard](https://traefik.kalny.net/dashboard).

### PDS

The PDS service is a decentralized social network that allows users to create and share content, including posts, comments, and likes.

To deploy:

```sh
docker stack deploy -c pds/compose.yaml pds
```

To validate the deployment, go to [https://bsky-debug.app/handle?handle=filip.kalny.net](https://bsky-debug.app/handle?handle=filip.kalny.net)

Secrets are stored in a gitignore pds/secrets.env file. To change the secrets, use this guide: [https://docs.docker.com/engine/swarm/secrets/#example-rotate-a-secret](https://docs.docker.com/engine/swarm/secrets/#example-rotate-a-secret)

### Baikal

Baikal is a self-hosted calendar and addressbook server.

To deploy:

```sh
docker stack deploy -c baikal/compose.yaml baikal
```

Dashboard is available at [https://baikal.kalny.net](https://baikal.kalny.net).

### Watchtower

Watchtower is a container that monitors the health of other containers and automatically restarts them if they fail.

To deploy:

```sh
docker stack deploy -c watchtower/compose.yaml watchtower
```
