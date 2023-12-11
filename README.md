
# Redis Cluster Deployment Script

## Overview
This project automates the deployment of a Redis cluster across multiple servers using Docker Compose. It involves setting up master and slave Redis nodes and configuring a Redis cluster environment. The deployment is managed by a Bash script named `deploy_redis_cluster.sh`. Additionally, the project includes a Python script for testing the deployed Redis cluster.

### Important Notes:
- The script sets up a cluster between master and slave nodes.
- A Redis cluster must have at least 3 master nodes for redundancy and failover purposes.
- If a master node goes down without an available slave node for it, the entire cluster may become unavailable.

## Pre-Installation Requirements
- Access to multiple servers with SSH enabled.
- Docker and Docker Compose installed on each server.
- The `redis.pem` private key file for SSH access to the servers.

## Installation
1. **Clone the Repository**: Clone this repository to your local machine.
2. **Prepare SSH Key**: Place your `redis.pem` SSH key in the project directory.

## Configuration
- **Server Configuration**: Define your master and slave nodes in the `deploy_redis_cluster.sh` script using the `MASTERS` associative array.
- **Redis Configuration**: The `redis.conf` file in the `docker-compose` directory should be set up for the Redis cluster configuration and recommended to use the default configuration file provided in the project.

## Deployment Steps
1. **Set Executable Permission**: Before running the script, ensure it has executable permissions: `chmod +x deploy_redis_cluster.sh`.
2. **Run the Script**: Execute the deployment script with `./deploy_redis_cluster.sh`.
   - The script will create the necessary directories on remote servers.
   - Docker Compose and Redis configuration files are transferred to each server.
   - Redis nodes are initiated and configured as per the master-slave setup.

## Post-Deployment
- The script automatically sets up the Redis cluster and generates a `startup_nodes_config.py` file for testing.
- Install the necessary Python library: `pip install redis-py-cluster`.
- Run the `test-redis.py` Python script in the `test-redis` directory to validate the Redis cluster setup using the command `python3 test-redis.py`.

## Testing the Redis Cluster
- **Run the Python Test Script**: Execute `test-redis.py`.
   - The script uses the `RedisCluster` object from the `rediscluster` package to connect to the Redis cluster.
   - It retrieves a value from the Redis cluster to validate the setup.

## Script Variables Explanation
- `LOCAL_CONF_PATH`: Path to local Docker Compose configuration. (use default)
- `TEST_REDIS_PATH`: Directory for Redis test scripts. (use default)
- `REMOTE_PATH`: Remote directory path for deployment. (use default)
- `USER`: SSH user for server access.
- `LOCAL_PRIVATE_KEY_PATH`: Path to SSH private key.
- `MASTERS`: Associative array defining master and slave nodes.

## Troubleshooting
- Ensure all servers have Docker and Docker Compose installed.
- Verify SSH access with the `redis.pem` key and user.
- Check the network connectivity between master and slave nodes.

## Additional Resources
For more documentation on Redis and its management, please visit the following resources:
- [Redis Scaling and Management Documentation](https://redis.io/docs/management/scaling/)
- [Official Redis Docker Hub](https://hub.docker.com/_/redis)

For Docker installation and setup, refer to these official resources:
- [Docker Engine Installation](https://docs.docker.com/engine/install/)
- [Docker Post-Installation Steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/)
- [Docker Compose Installation](https://docs.docker.com/compose/install/)

## Contributing
Contributions to the project are welcome. Please submit pull requests for any enhancements or fixes.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Contact
For support or feedback, please contact [ahmed.i.ibrahim@outlook.com](mailto:ahmed.i.ibrahim@outlook.com).
