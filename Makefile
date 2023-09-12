REPO = ghcr.io/mopidy
IMAGE = gst-plugin-spotify-build
VERSION = $(shell cat VERSION)

.PHONY: build release git-release docker-release

build: docker-build build-armhf build-x86_64

build-armhf:
	docker run -v ./../gst-plugins-rs:/gst-plugins-rs:z -v .:/gst-plugin-spotify-build:z ${REPO}/${IMAGE}:${VERSION} /bin/bash /gst-plugin-spotify-build/entrypoint.sh armhf
	
docker-build:
	docker build --tag ${REPO}/${IMAGE}:${VERSION} --file Dockerfile .

release: git-release docker-release

git-release:
	git diff-index --quiet HEAD || (echo "Git repo is unclean"; false)
	git tag -a "${IMAGE}/${VERSION}" -m "Release ${IMAGE}:${VERSION}"
	git push --follow-tags

docker-release:
	docker tag ${REPO}/${IMAGE}:${VERSION} ${REPO}/${IMAGE}:latest
	docker push ${REPO}/${IMAGE}:${VERSION}
	docker push ${REPO}/${IMAGE}:latest
