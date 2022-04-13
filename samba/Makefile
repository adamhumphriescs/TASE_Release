all: start
	docker exec -it $$(cat container_id) bash

.PHONY: start
start: container_id

container_id:
	docker run -it --mount type=bind,src=$$(pwd)/build_script.sh,dst=/build_script.sh --mount type=bind,src=$$(pwd)/recompile.sh,dst=/recompile.sh --mount type=bind,src=$$(pwd)/harness.c,dst=/harness.c --mount type=bind,src=/winhomes/jsg57/current/TASE_Release/install/taseglob,dst=/TASE/install/taseglob  --mount type=bind,src=/winhomes/jsg57/md5sum/,dst=/md5sum/ -d samba > container_id
	cat container_id

end: container_id
	docker stop $$(cat container_id)
	docker rm $$(cat container_id)
	rm -f container_id

container:
	nohup docker build --no-cache --network=host -t samba . 2>&1 > err.log &
