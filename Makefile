oidc_server_container=wk-oidc-server
docker-compose := $(shell command -v docker-compose 2> /dev/null || echo "docker compose")
OUTLINE_VERSION = local

gen-conf:
	cd ./scripts && cp config.sh.sample config.sh && bash ./main.sh init_cfg
	
build:
	cd ./outline && make up 
	cd ./outline && make OUTLINE_VERSION=${OUTLINE_VERSION} build

start:
	${docker-compose} up -d
	cd ./scripts && bash ./main.sh reload_nginx

test:
	cd ./outline && make test

watch:
	cd ./outline && make watch

install: start
#	1001 is the user id of the user in the container
	@sudo mkdir -p ./data/outline && sudo chown -R 1001 ./data/outline && sudo -k

	sleep 1
	${docker-compose} exec ${oidc_server_container} bash -c "make init"
	${docker-compose} exec ${oidc_server_container} bash -c "python manage.py loaddata oidc-server-outline-client"
	cd ./scripts && bash ./main.sh reload_nginx

restart: stop start

logs:
	${docker-compose} logs -f

stop:
	${docker-compose} down || true

update-images:
	${docker-compose} pull

clean-docker: stop
	${docker-compose} rm -fsv || true

clean-conf:
	rm -rfv env.* .env docker-compose.yml config/uc/fixtures/*.json \
		config/nginx

clean-data: clean-docker
	rm -rfv ./data/certs ./data/minio_root \
		./data/pgdata ./data/uc ./data/outline
	cd ./outline && make clean

clean: clean-docker clean-conf

