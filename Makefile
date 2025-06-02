# Define the Docker Compose command with the correct file and .env
COMPOSE = docker-compose -f ./srcs/compose.yml --env-file $(PWD)/srcs/.env

# Define expected secret files
SECRETS := secrets/db_password.txt secrets/db_root_password.txt secrets/wp_admin_password.txt

# Default target: runs the infrastructure
all: up

# Ensure all required secret files exist
$(SECRETS):
	@if [ ! -f "$@" ]; then \
		echo "Error: Missing secret file: $@"; exit 1; \
	fi

# Adds local DNS entry for the domain if it's not already in /etc/hosts
add_host:
	@if ! grep -q "wdegraf.42.fr" /etc/hosts; then \
		echo "127.0.0.1 wdegraf.42.fr" | sudo tee -a /etc/hosts; \
	fi

# Create persistent volume directories with correct permissions
data_bases:
	mkdir -p /home/wdegraf/data/wordpress /home/wdegraf/data/mariadb
	sudo chown -R 3000:3000 /home/wdegraf/data/mariadb
	sudo chown -R www-data:www-data /home/wdegraf/data/wordpress

# Create named volumes for WordPress and MariaDB using bind mounts
named_volumes:
	docker volume create \
		--driver local \
		--opt type=none \
		--opt device=/home/wdegraf/data/wordpress \
		--opt o=bind \
		wordpress_data
	docker volume create \
		--driver local \
		--opt type=none \
		--opt device=/home/wdegraf/data/mariadb \
		--opt o=bind \
		mariadb_data


# Main setup: prepare host, check secrets, create volumes, and start containers
up: add_host data_bases named_volumes $(SECRETS)
	$(COMPOSE) up -d

# Rebuild all containers without removing volumes
re:
	$(COMPOSE) up --build -d

# Stop and remove containers (but not volumes/images)
down:
	$(COMPOSE) down

# Stop running containers without removing them
stop:
	$(COMPOSE) stop

# Start previously stopped containers
start:
	$(COMPOSE) start

# Remove containers, volumes, images, and do a full prune
clean:
	$(COMPOSE) down -v --remove-orphans
	@if [ -n "$(shell docker images -q)" ]; then \
		docker rmi -f $(shell docker images -q); \
	fi
	docker system prune -af --volumes

# Full clean: remove everything and reset host entries
# ⚠️ WARNING: fclean is destructive. Uncomment only if you need to wipe all volumes and start fresh.
# fclean: clean
# 	sudo sed -i "/wdegraf.42.fr/d" /etc/hosts
# 	sudo rm -rf /home/wdegraf/data/*

# Test if the server is reachable (ignores invalid certs)
test_curl:
	curl -I https://wdegraf.42.fr --insecure

# Tail logs from all containers
logs:
	$(COMPOSE) logs -f --tail=100

# Declare all targets that don't create files
.PHONY: all up down stop start clean fclean re logs test_curl data_bases add_host
