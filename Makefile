#!/bin/bash

UID = $(shell id -u)
DOCKER_BE = symfony-app

help: ## Show this help message
	@echo 'usage: make [target]'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done | column -t -c 2 -s ':#'

start: ## Start the containers
	cp -n docker-compose.yml.dist docker-compose.yml || true
	U_ID=${UID} docker compose up -d

stop: ## Stop the containers
	U_ID=${UID} docker compose stop

restart: ## Restart the containers
	$(MAKE) stop && $(MAKE) start

build: ## Rebuilds all the containers
	cp -n docker-compose.yml.dist docker-compose.yml || true
	U_ID=${UID} docker compose build

prepare: ## Runs backend commands
	$(MAKE) composer-install
	$(MAKE) cs-install
	$(MAKE) install-hooks

run: ## starts the Symfony development server in detached mode
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} symfony serve -d

logs: ## Show Symfony logs in real time
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} symfony server:log

# Backend commands
composer-install: ## Installs composer dependencies
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} composer install --no-interaction
	
composer-require: ## Installs a composer dependency. Usage: make composer-require PACKAGE=vendor/package [DEV=true]
	$(if $(PACKAGE),,$(error PACKAGE is required. Usage: make composer-require PACKAGE=vendor/package))
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} composer require $(if $(filter true,$(DEV)),--dev )$(PACKAGE) --no-interaction
# End backend commands

make-module: ## Creates a hexagonal module under src/. Usage: make make-module NAME=ModuleName
	$(if $(NAME),,$(error NAME is required. Usage: make make-module NAME=ModuleName))
	mkdir -p src/$(NAME)/Application src/$(NAME)/Domain src/$(NAME)/Infrastructure
	@echo "Module '$(NAME)' created at src/$(NAME)/ with Application, Domain and Infrastructure layers."

ssh: ## bash into the be container
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} bash

# Git hooks
install-hooks: ## Configure git to use .githooks/
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit

# Code quality
cs-install: ## Install PHP CS Fixer dependencies
	cd tools/php-cs-fixer && composer install --no-interaction

cs-fix: ## Run PHP CS Fixer (fix mode)
	tools/php-cs-fixer/vendor/bin/php-cs-fixer fix src --verbose --show-progress=dots

cs-check: ## Run PHP CS Fixer (dry-run mode)
	tools/php-cs-fixer/vendor/bin/php-cs-fixer fix src --dry-run --diff --verbose --show-progress=dots

phpstan: ## Run PHPStan static analysis
	U_ID=${UID} docker exec --user ${UID} ${DOCKER_BE} vendor/bin/phpstan analyse -c phpstan.dist.neon
