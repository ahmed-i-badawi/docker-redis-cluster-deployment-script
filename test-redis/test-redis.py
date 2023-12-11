from rediscluster import RedisCluster
from startup_nodes_config import startup_nodes

# Create the RedisCluster object
cluster = RedisCluster(startup_nodes=startup_nodes,
                        decode_responses=True,
                        skip_full_coverage_check=True)

#cluster.set("my_key", "my_value")
value = cluster.get("my_key")
print("Retrieved value:", value)

cluster.close()
