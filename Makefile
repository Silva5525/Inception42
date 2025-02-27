COMPOSE = docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env

SECRETS := secrets/db_password.txt secrets/db_root_password.txt

$(SECRETS):
	@if [ ! -f "$@" ]; then \
		echo "Error: Missing secret file: $@"; exit 1; \
	fi

data_bases:
	mkdir -p ~/data/wordpress ~/data/mariadb

all: up

up:
	$(COMPOSE) up -d

re:
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

clean:
	$(COMPOSE) down -v --remove-orphans
	@if [ -n "$(shell docker images -q)" ]; then \
		$(DOCKER) rmi -f $(shell docker images -q); \
	fi
	$(DOCKER) system prune -af --volumes

# fclean: clean
# 	rm -rf ~/data/wordpress ~/data/mariadb

test_curl:
	curl -I https://${USER}.42.fr --insecure

.PHONY: all up down stop start clean fclean re logs test_curl data_bases