COMPOSE = USER=$(USER) docker-compose -f ./srcs/compose.yml --env-file srcs/.env

SECRETS := secrets/db_password.txt secrets/db_root_password.txt secrets/wp_admin_password.txt

all: up

$(SECRETS):
	@if [ ! -f "$@" ]; then \
		echo "Error: Missing secret file: $@"; exit 1; \
	fi

# Add ${USER}.42.fr to /etc/hosts if not already present
add_host:
	@if ! grep -q "${USER}.42.fr" /etc/hosts; then \
		echo "127.0.0.1 ${USER}.42.fr" | sudo tee -a /etc/hosts; \
	fi

data_bases:
	mkdir -p ~/data/wordpress ~/data/mariadb

up: add_host data_bases $(SECRETS)
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
		docker rmi -f $(shell docker images -q); \
	fi
	docker system prune -af --volumes

fclean: clean
	sudo sed -i '/${USER}.42.fr/d' /etc/hosts
	rm -rf ~/data/wordpress ~/data/mariadb

test_curl:
	curl -I https://${USER}.42.fr --insecure

logs:
	$(COMPOSE) logs -f --tail=100

.PHONY: all up down stop start clean fclean re logs test_curl data_bases add_host 