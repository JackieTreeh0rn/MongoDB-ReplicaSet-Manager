
# MongoDB ReplicaSet Manager for Docker Swarm

`Version: 1.04`

## Introduction
This tool automates the configuration, initiation, monitoring, and management of a MongoDB replica set within a Docker Swarm environment. It ensures continuous operation, and adapts to changes within the Swarm network, ensuring high availability and consistency of data.

## Features
- ✅ **Intelligent Fresh Deployment**: Configures and initiates MongoDB replica set from scratch with smart node detection, accounting for 'down' or 'unavailable' swarm nodes and deployment constraints.

- ✅ **Smart Redeployment Detection**: Automatically detects container redeployments with changed IP addresses and immediately updates configuration without unnecessary delays or false initialization attempts.

- ✅ **Optimized Performance**: Fast reconfiguration during full redeployments with intelligent primary detection using current task IPs instead of stale configuration data.

- ✅ **Advanced Startup Handling**: Robust retry logic handles MongoDB transitional states (NotYetInitialized) during startup, distinguishing between temporary states and actual fresh deployments.

- ✅ **Primary Node Management**: Automatic primary designation, tracking, and failover handling with intelligent election timeout and forced reconfiguration when needed.

- ✅ **Dynamic Scaling**: Real-time addition and removal of MongoDB nodes during runtime with automatic replica set reconfiguration and member management.

- ✅ **Comprehensive User Setup**: Automated creation of MongoDB admin (root) accounts and initial application database users with proper authentication and permissions.

- ✅ **Continuous Topology Monitoring**: Watches Docker Swarm changes and adjusts replica set configuration for IP changes, node additions/removals, and network topology updates.

- ✅ **Production-Ready Logging**: Color-coded ANSI logging with contextual messages, eliminating misleading errors during normal operations and providing clear troubleshooting information.

- ✅ **Enterprise Scalability**: Designed for multi-node Docker Swarm environments with automatic scaling, tested against various outage scenarios and edge cases for maximum reliability.

> **Note:** Primary discovery now uses MongoDB's `hello` command and checks `isWritablePrimary` for accuracy across server versions.

## Requirements
* [x] **MongoDB**: version 8.0.x (recipe uses `8.0.13`). 7.0 is compatible but not defaulted here.
* [x] **PyMongo Driver**: 4.15.x — pinned to `>=4.15,<5` and included in the controller image.
* [x] **Docker**: tested on >= `24.0.5`.
* [x] **Operating System**: Linux (tested on >= `Ubuntu 23.04`). <br/>**[mongo-replica-ctrl](https://hub.docker.com/r/jackietreehorn/mongo-replica-ctrl)** image supports:
    `linux/amd64`, `linux/arm/v7`, `linux/arm64`

## Prerequisites
- A [Docker Swarm cluster](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/) (*locally or in the cloud as you prefer*) - tested on 6 node Swarm cluster.
- Docker Stack recipe - see [`docker-compose-stack.yml`](./docker-compose-stack.yml)
- Environment variables - see [`mongo-rs.env`](./mongo-rs.env)
- Deployment script [`deploy.sh`](./deploy.sh)

## How to Use

**TL;DR:**<br/>
- `git clone https://github.com/JackieTreeh0rn/MongoDB-ReplicaSet-Manager`
- `./deploy.sh`
<br/>
1. Ensure that all required environment variables are set in [`mongo-rs.env`](./mongo-rs.env) (see environment variables below). <br/>

2. Modify the `docker-compose-stack.yml` to add your main application making use of the mongo service.
**Note** - set your application's MongoDB URI to use the following connection string when connecting to the replica set service:<br/>

    `mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@database:27017/?replicaSet=${REPLICASET_NAME}`


3. Deploy the compose stack on your Docker Swarm using the `deploy.sh` script via:
[`./deploy.sh`](/deploy.sh) - this will perform the following actions:<br/>
    - Import ENVironment variables.
    - Create **backend** 'overlay' network with encryption enabled.
    - Generate a `keyfile` for the replicaSet and add it as a Docker "secret" for the stack to use.
    - Spin-up the various docker stack services: mongo, dbcontroller, nosqlclient, your application or service.
    - The dbcontroller tool will run as a single instance per Swarm node (***global*** mode) as defined in the Compose YML. <br/>

4. Monitor logs for the tool's output and any potential errors or adjustments *(see troubleshooting section)* <br/>

5. To remove, run [`./remove.sh`](/remove.sh) or delete the stack manually via `docker stack rm [stackname]`.
**Note:**  the `_backend` 'overlay' network created during initial deployment will not be removed automatically as it is considered external. If redeploying/updating, leave the existing network in place so as to retain the original network subnet.

## Environment Variables
The script requires the following environment variables, defined in `mongo-rs.env`:
* `STACK_NAME`, the default value is `myapp`
* `MONGO_VERSION`, the default value is `8.0.13`
* `REPLICASET_NAME`, the default value is `rs`
* `BACKEND_NETWORK_NAME`, the default value is `${STACK_NAME}_backend`
* `MONGO_SERVICE_URI`, the default value is `${STACK_NAME}_database`
* `MONGO_ROOT_USERNAME`, the default value is `root`
* `MONGO_ROOT_PASSWORD`, the default value is `password123`
* `INITDB_DATABASE`, the default value is `myinitdatabase`
* `INITDB_USER`, the default value is `mydbuser`
* `INITDB_PASSWORD`, the default value is `password`


## How It Works
- **Smart Discovery**: Identifies and assesses MongoDB services in the Docker Swarm with intelligent node state detection and constraint handling.
- **Deployment Intelligence**: Distinguishes between fresh deployments, redeployments with IP changes, and dynamic scaling scenarios using advanced configuration analysis.
- **Optimized Configuration**: Uses current task IPs for primary detection during redeployments, eliminating delays from stale configuration data.
- **Adaptive Management**: Handles MongoDB startup transitional states with retry logic, ensuring reliable operation across various deployment scenarios.
- **Real-time Monitoring**: Continuously adapts replica set configuration for network changes, node lifecycle events, and topology updates with minimal downtime.
* The [nosqlclient](https://www.nosqlclient.com/) service included in the recipe can be used to access and manage the db - upon launching the nosqlclient front-end via `http://<any-swarm-node-ip>:3030`, click connect to select a database to view/manage.
- The included compose YML will use the latest version available on [DockerHub](https://hub.docker.com) via [jackietreehorn/mongo-replica-ctrl](https://hub.docker.com/r/jackietreehorn/mongo-replica-ctrl)  . Alternatively, you can use `docker pull jackietreehorn/mongo-replica-ctrl:latest` to pull the latest version and push it onto your own repo.  Additionally, the included [`./build.sh`](/build.sh) allows you to build the docker image locally as well.

## Troubleshooting / Additional Details
* **Logs** - check the Docker service logs for the mongo controller service for details about its operation (enable `DEBUG:1` in compose YML if you want more detail). The controller uses **colored ANSI logging** to highlight important information:
  - 🟢 **GREEN**: INFO messages
  - 🟡 **YELLOW**: WARNING messages and IP addresses
  - 🔴 **RED**: ERROR messages
  - 🟣 **MAGENTA**: PRIMARY nodes (bold)
  - 🔵 **CYAN**: SECONDARY nodes and DEBUG messages
  - **BOLD**: ReplicaSet-related terms

  If you do not use something like [Portainer](https://docs.portainer.io/start/install-ce/server/swarm) or similar web frontend to manage Docker, you can follow the controller logs via CLI on one of your docker nodes via: `docker service logs [servicename]_dbcontroller --follow`

    Example:

    ```
    docker service logs myapp_dbcontroller --follow --details
    ```

    ```| INFO:__main__:Checking Task IP: 10.0.26.48 for primary...
    | INFO:__main__:Expected number of mongodb nodes: {6} | Remaining to start: {0}
    | INFO:__main__:Mongo service nodes are up and running!
    | INFO:__main__:Mongo tasks ips: ['10.0.26.48', '10.0.26.52', '10.0.26.51', '10.0.26.49', '10.0.26.7', '10.0.26.4']
    | INFO:__main__:Inspecting Mongo nodes for pre-existing replicaset - this might take a few moments, please be patient...
    | INFO:__main__:Pre-existing replicaSet configuration found in node 10.0.26.48: {'10.0.26.52', '10.0.26.51', '10.0.26.49', '10.0.26.4', '10.0.26.7', '10.0.26.48'}
    | INFO:__main__:Checking Task IP: 10.0.26.52 for primary...
    | INFO:__main__:Checking Task IP: 10.0.26.51 for primary...
    | INFO:__main__:Checking Task IP: 10.0.26.7 for primary...
    | INFO:__main__:Checking Task IP: 10.0.26.48 for primary...
    | INFO:__main__:--> Mongo ReplicaSet Primary is: 10.0.26.48 <--

- **Environment** - verify that all required environment variables are correctly set in [`mongo-rs.env`](./mongo-rs.env).

* **Docker Stack Compose YML** - ensure that the MongoDB service is correctly configured and accessible within the Docker Swarm - see compose file for standard configuration. The *dbcontroller* that maintains the status of the replica-set must be deployed in a single instance over a Swarm manager node (see [`docker-compose-stack.yml`](./docker-compose-stack.yml)).  **Multiple instances of the Controller, may perform conflicting actions!**  Also, to ensure that the controller is restarted in case of error, there is a restart policy in the controller service definition.

  ***IMPORTANT***: The default MongoDB port is `27017`.  This port is only used internally by the services/applications in the compose YML and it is <u>**not**</u> published outside the Swarm by design.  Changing or publishing this port in the YML configuration will break management of the mongodb replicaSet.

* **Firewalls / SELinux** - Linux distributions using [SELinux](https://www.redhat.com/en/topics/linux/what-is-selinux) are well known for causing [issues with MongoDB](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-red-hat/). To check if your distribution is using SELinux you can run `sestatus` and either disable it or [configure it for mongodb](https://severalnines.com/blog/how-configure-selinux-mongodb-replica-sets/) if you must absolutely use it.  Additionally, ensure your distribution's firewall is disabled during testing or configured for Mongo - check your distribution docs for appropiate steps (eg. `systemctl status firewalld`, `ufw status`, etc).

* **Networking** - the `_backend` 'overlay' external network created during initial deployment is assigned an address space (eg. ***10.0.25.0***) automatically by Docker. You can define your own network space by uncommenting the relevant section in [`deploy.sh`](./deploy.sh) and adjusting as needed, in the event of overlap with other subnets in your network (*this should only be needed in extremely rare ocassions*). In addition, **DO NOT** remove this network when re-deploying / updating your stack on top of an existing-working replicaSet configuration so as to avoid subnet changes and connectivity issues between re-deployments.

- **Persistent Data** - to use data persistence, the *mongo* service needs to be deployed in [**global mode**](https://docs.docker.com/compose/compose-file/deploy/#mode) (see `docker-compose-stack.yml`). This is to avoid more than one instance being deployed on the same node and prevent different instances from concurrently accessing the same MongoDB data space on the filesystem.  The volumes defined in the compose YML allow for each mongo node to use its own dedicated data store.  They are also set as external so that they aren't inadvertenly deleted or recreated between service redeployments.

* **Swarm Nodes** - for HA purposes, your Swarm cluster should have more than one manager. This allows the *controller* to start/restart on different nodes in case of issues.

- **Healthchecks** - the Mongo **health check script** [mongo-healthcheck](./mongo-healthcheck) serves only to verify the status of the MongoDB service. No check on mongo cluster status is made. The cluster status is checked and managed by the ***dbcontroller*** service. I use *Docker Configs* to pass the MongoDB health check script to the MongoDB containers - this is done automatically by Docker once the compose stack is deployed. The script is POSIX `sh` compatible (no Bash required) and uses `mongosh` to `ping` the server.

- **MongoDB Configuration Check** - the Mongo [`./docker-mongodb_config-check.sh`](./docker-mongodb_config-check.sh) script can be run from any docker manager node to locate and connect to a mongodb instance in the swarm and fetch configuration information.  It runs `rs.status()` and `rs.config()` and returns the output. This can help in validating/correlating the config's ***PRIMARY*** shown, against the **dbcontroller** logs, in addition to other relevant configuration information for your replicaSet.


    Example:

   ``````
   ./docker-mongodb_config-check.sh
   ``````


    ``````
    members: [
        {
        _id: 1,
        name: '10.0.26.51:27017',
        health: 1,
        state: 2,
        stateStr: 'SECONDARY',
        uptime: 20842,
        optime: { ts: Timestamp({ t: 1701196480, i: 1 }), t: Long("26") },
        optimeDurable: { ts: Timestamp({ t: 1701196480, i: 1 }), t: Long("26") },
        optimeDate: ISODate("2023-11-28T18:34:40.000Z"),
        optimeDurableDate: ISODate("2023-11-28T18:34:40.000Z"),
        lastAppliedWallTime: ISODate("2023-11-28T18:34:40.505Z"),
        lastDurableWallTime: ISODate("2023-11-28T18:34:40.505Z"),
        lastHeartbeat: ISODate("2023-11-28T18:34:54.484Z"),
        lastHeartbeatRecv: ISODate("2023-11-28T18:34:54.798Z"),
        pingMs: Long("6"),
        lastHeartbeatMessage: '',
        syncSourceHost: '10.0.26.52:27017',
        syncSourceId: 5,
        infoMessage: '',
        configVersion: 1521180,
        configTerm: 26
        },
        {
        _id: 2,
        name: '10.0.26.48:27017',
        health: 1,
        state: 1,
        stateStr: 'PRIMARY',     <-------------------------- SHOULD match log's outout for Primary
        uptime: 20843,
        optime: { ts: Timestamp({ t: 1701196480, i: 1 }), t: Long("26") },
        optimeDurable: { ts: Timestamp({ t: 1701196480, i: 1 }), t: Long("26") },
        optimeDate: ISODate("2023-11-28T18:34:40.000Z"),
        optimeDurableDate: ISODate("2023-11-28T18:34:40.000Z"),
        lastAppliedWallTime: ISODate("2023-11-28T18:34:40.505Z"),
        lastDurableWallTime: ISODate("2023-11-28T18:34:40.505Z"),
        lastHeartbeat: ISODate("2023-11-28T18:34:54.698Z"),
        lastHeartbeatRecv: ISODate("2023-11-28T18:34:55.156Z"),
        pingMs: Long("8"),
        lastHeartbeatMessage: '',
        syncSourceHost: '',
        syncSourceId: -1,
        infoMessage: '',
        electionTime: Timestamp({ t: 1701152367, i: 1 }),
        electionDate: ISODate("2023-11-28T06:19:27.000Z"),
        configVersion: 1521180,
        configTerm: 26
        }
    ``````

- **Service Start-up**  - please note that depending on the number of nodes in your swarm and your connection speed, it might take some time for images to download, for the mongodb instances to spin up, and the replica manager to configure the replica-set. Services in the compose stack YML recipe, such as `nosqlclient`, `[your mongo application]`, etc, that depend on the mongo database to be operational, should be allowed enough time to start (*particularly upon an initial/blank-slate deployment*) before showing as **READY**.  Additionally, docker might fail/restart services that are dependent on mongodb when starting things up if the mongo service isn't ready and configured - **this is normal** for initial deployments and services will connect to mongo when available.

    ***MongoDB operating in replicaset mode will not become available for use until the replicaset configuration is finalized and a primary instance is elected.***

## References & Versioning Notes
- PyMongo driver docs: https://www.mongodb.com/docs/languages/python/pymongo-driver/current/
- PyMongo API docs: https://pymongo.readthedocs.io/en/4.15.1/api/
- This project pins:
    - PyMongo: `>=4.15,<5` (compatible with MongoDB 7.x/8.x and Python 3.13)
    - Docker SDK for Python: `>=7,<9` to follow latest 7.x without adopting future breaking major changes automatically.

## Contact
   - Discord: [discordapp.com/users/916819244048592936](https://discordapp.com/users/916819244048592936)
   - GitHub: [github.com/jackietreeh0rn](https://github.com/jackietreeh0rn)
   - DockerHub: [hub.docker.com/u/jackietreehorn](https://hub.docker.com/u/jackietreehorn)
