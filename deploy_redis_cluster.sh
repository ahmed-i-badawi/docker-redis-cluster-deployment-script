#!/bin/bash

########################################################################
# start Define variables
LOCAL_CONF_PATH=docker-compose
TEST_REDIS_PATH="test-redis"

REMOTE_PATH="~/redis" # remote path to deploy in (will be created automatically)
USER="ec2-user" # you servers user which must be the same for all servers
LOCAL_PRIVATE_KEY_PATH="./redis.pem"  # Replace with the path to your servers private key which must be the same for all servers
# Define master and slave (space-separated) nodes using an associative array with ports
# ex. if we have 10 servers (note: ports don't matter, anything but ports need to be allowed on server)
# master-1 => 34.194.97.1:7415
# slave-1 for master-1 => 34.194.97.4:5645
# slave-2 for master-1 => 34.194.97.5:7899

# master-2 => 34.194.97.2:8456
# slave-1 for master-2 => 34.194.97.6:5941
# slave-2 for master-2 => 34.194.97.7:7199

# master-3 => 34.194.97.3:6379
# slave-1 for master-3 => 34.194.97.8:5941
# slave-2 for master-3 => 34.194.97.9:7199
# slave-3 for master-3 => 34.194.97.9:7125

# your MASTERS variable will like this
declare -A MASTERS=(
    ["34.194.97.1:7415"]="34.194.97.4:5645 34.194.97.5:7899"
    ["34.194.97.2:8456"]="34.194.97.6:5941 34.194.97.7:7199"
    ["34.194.97.3:6379"]="34.194.97.8:5941 34.194.97.9:7199 34.194.97.9:7125"
)

# End Define variables
########################################################################

# Function to deploy Docker Compose and redis.conf to a server
init_deploy() {
    local server_ip="$1"
    local redis_ip="$2"
    local role="$3"
    local redis_port="$4"
    local master_ip_for_slave="$5"
    local dir_relative_path=""
    if [ "$role" == "master" ]; then
         dir_relative_path=$role
    fi
    if [ "$role" == "slave" ]; then
         dir_relative_path=slave-for-master-$master_ip_for_slave
    fi
    
    
    echo "Deploying Docker Compose and redis.conf to $role: $server_ip"

    # Create directory structure
    ssh -o StrictHostKeyChecking=no -i "$LOCAL_PRIVATE_KEY_PATH" "$USER@$server_ip" "mkdir -p $REMOTE_PATH/$dir_relative_path"

    # Copy the Docker Compose file and redis.conf to the server
    scp -o StrictHostKeyChecking=no -i "$LOCAL_PRIVATE_KEY_PATH" $LOCAL_CONF_PATH/docker-compose.yml $LOCAL_CONF_PATH/redis.conf "$USER@$server_ip:$REMOTE_PATH/$dir_relative_path/"

    # Update Redis configuration file with the appropriate port
    ssh -o StrictHostKeyChecking=no -i "$LOCAL_PRIVATE_KEY_PATH" "$USER@$server_ip" "echo -e '\nport $redis_port' >> $REMOTE_PATH/$dir_relative_path/redis.conf"

    # Update Docker Compose file with the appropriate ports
    ssh -o StrictHostKeyChecking=no -i "$LOCAL_PRIVATE_KEY_PATH" "$USER@$server_ip" <<-EOF
        # Append ports to the Docker Compose file
        
        echo -e "\n    container_name: redis-$dir_relative_path" >> $REMOTE_PATH/$dir_relative_path/docker-compose.yml
        # echo -e "    ports:" >> $REMOTE_PATH/$dir_relative_path/docker-compose.yml
        # echo -e "      - $redis_port:$redis_port" >> $REMOTE_PATH/$dir_relative_path/docker-compose.yml
        # echo -e "      - 1$redis_port:1$redis_port" >> $REMOTE_PATH/$dir_relative_path/docker-compose.yml
EOF

    # SSH into the server and execute Docker Compose commands
    ssh -o StrictHostKeyChecking=no -i "$LOCAL_PRIVATE_KEY_PATH" "$USER@$server_ip" "docker-compose -f $REMOTE_PATH/$dir_relative_path/docker-compose.yml down && docker-compose -f $REMOTE_PATH/$dir_relative_path/docker-compose.yml up -d"

    echo "Deployment to role: $role server: $server_ip service: $redis_ip port: $redis_port completed"
}

# Iterate through master-slave mapping s and deploy nodes
deploy() {
    for master in "${!MASTERS[@]}"; do
        master_ip=$(echo "$master" | cut -d':' -f1)
        master_port=$(echo "$master" | cut -d':' -f2)
        slave_info=${MASTERS[$master]}

        #init_deploy server_ip redis_ip role redis_port
        init_deploy "$master_ip" "$master_ip" "master" "$master_port"

        IFS=' ' read -r -a slave_array <<< "$slave_info"
        for slave in "${slave_array[@]}"; do
            slave_ip=$(echo "$slave" | cut -d':' -f1)
            slave_port=$(echo "$slave" | cut -d':' -f2)

            init_deploy "$slave_ip" "$slave_ip" "slave" "$slave_port" "$master_ip"
        done
    done
}

# Function to create Redis cluster
create_redis_cluster() {
    local master_nodes=("${!MASTERS[@]}")

    # Construct a string with nodes and ports for cluster creation
    local nodes_with_ports=""
    for node in "${master_nodes[@]}"; do
        nodes_with_ports+=" $node"
    done

    # Initialize Redis cluster on the first master node
    local first_master="${master_nodes[0]}"
    local first_master_ip=$(echo "$first_master" | cut -d':' -f1)

    ssh -o StrictHostKeyChecking=no -i "$LOCAL_PRIVATE_KEY_PATH" "$USER@$first_master_ip" << EOF
        # Execute Redis CLI commands inside the container for cluster initialization
        docker exec -u 0 redis-master /bin/bash -c "echo 'yes' | redis-cli --cluster create $nodes_with_ports"
EOF

    echo "Redis cluster created with master nodes: ${nodes_with_ports[*]}"

    # Add slave nodes to each master node
    for master in "${master_nodes[@]}"; do
        local master_ip=$(echo "$master" | cut -d':' -f1)
        local master_port=$(echo "$master" | cut -d':' -f2)

        for slave in ${MASTERS[$master]}; do
            if [ -n "$slave" ]; then
                local slave_ip=$(echo "$slave" | cut -d':' -f1)
                local slave_port=$(echo "$slave" | cut -d':' -f2)
                ssh -o StrictHostKeyChecking=no -i "$LOCAL_PRIVATE_KEY_PATH" "$USER@$first_master_ip" << EOF
                    # Execute Redis CLI commands inside the container for adding nodes
                    docker exec -u 0 redis-master redis-cli --cluster add-node "$slave_ip:$slave_port" "$master_ip:$master_port" --cluster-slave --cluster-yes
EOF
                echo "Added slave $slave to master $master"
            fi
        done
    done
}

set_test_redis() {
    echo "startup_nodes = [" > $TEST_REDIS_PATH/startup_nodes_config.py
    for master in "${!MASTERS[@]}"; do
        local master_ip=${master%:*}
        local master_port=${master#*:}
        echo "   {'host': '$master_ip', 'port': $master_port}, # master" >> $TEST_REDIS_PATH/startup_nodes_config.py

        local slaves=(${MASTERS[$master]})
        for slave in "${slaves[@]}"; do
            local slave_ip=${slave%:*}
            local slave_port=${slave#*:}
            echo "   {'host': '$slave_ip', 'port': $slave_port}, # slave for $master_ip" >> $TEST_REDIS_PATH/startup_nodes_config.py
        done
    done
    echo "]" >> $TEST_REDIS_PATH/startup_nodes_config.py
}

deploy
create_redis_cluster
set_test_redis