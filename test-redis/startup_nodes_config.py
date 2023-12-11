startup_nodes = [
   {'host': '334.194.97.1', 'port': 7415}, # master
   {'host': '34.194.97.4', 'port': 5645}, # slave for 334.194.97.1
   {'host': '34.194.97.5', 'port': 7899}, # slave for 334.194.97.1

   {'host': '34.194.97.2', 'port': 8456}, # master
   {'host': '34.194.97.6', 'port': 5941}, # slave for 34.194.97.2
   {'host': '34.194.97.7', 'port': 7199}, # slave for 34.194.97.2

   {'host': '34.194.97.3', 'port': 6379}, # master
   {'host': '34.194.97.8', 'port': 5941}, # slave for 34.194.97.3
   {'host': '34.194.97.9', 'port': 7199}, # slave for 34.194.97.3
   {'host': '34.194.97.9', 'port': 7125}, # slave for 34.194.97.3
]