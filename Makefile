next-version-file = .next-version
version-file = .version
version = $(shell cat $(version-file))
image = tatu-tasks:$(version)
remote-image-prefix = gcr\.io\/playax18\/tatu-tasks
remote-image = $(remote-image-prefix)\:$(version)

.PHONY: all build tag_old_image rm_old_image run stop clean major minor patch current update_version deploy

v:
	@echo $(version)

all: tag_old_image build rm_old_image

build:
	docker build . -t $(image)

tag_old_image:
	@-docker tag $(image) $(image)-old 2>/dev/null

rm_old_image:
	@-docker rmi $(image)-old 2>/dev/null


run:
	docker run --rm -it --name tatu-tasks -v $(PWD):/tatu-tasks -p 9292:9292 -e APP_ENV=development -e RACK_ENV=development $(image)

stop:
	-docker stop tatu-tasks

clean: stop
	-docker rm tatu-tasks
	-docker rmi $(image) $(remote-image)

major: awk-directive = $$1+1 ".0.0"
major: update_version build

minor: awk-directive = $$1 "." $$2+1 ".0"
minor: update_version build

patch: awk-directive = $$1 "." $$2 "." $$3+1
patch: update_version build

current: all
	@:

update_version:
	awk -F. '{ print $(awk-directive) }' $(version-file) > $(next-version-file)
	mv $(next-version-file) $(version-file)

version_check:
	@( read -p "Deploy image $(image)? [y/n] " ans && case "$$ans" in [yY]) true;; *) false;; esac )

deploy: version_check
	docker tag $(image) $(remote-image)
	docker push $(remote-image)
	docker rmi $(remote-image)
	sed -E 's/$(remote-image-prefix)\:[0-9.]+/$(remote-image)/g' kubernetes.yaml > temp_kube.yaml
	mv temp_kube.yaml kubernetes.yaml
	kubectl apply -f kubernetes.yaml
	git tag $(version)
	git push origin $(version)
