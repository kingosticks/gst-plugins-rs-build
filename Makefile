REPO = ghcr.io/mopidy
IMAGE = gst-plugins-rs-build
VERSION = $(shell cat VERSION)

.PHONY: build release git-release docker-release

build: docker-build build-armhf build-x86_64

build-armhf:
	docker run -v $(pwd)/../gst-plugins-rs:/gst-plugins-rs:z -v $(pwd):/gst-plugins-rs-build:z ${REPO}/${IMAGE}:${VERSION} /bin/bash /gst-plugins-rs-build/entrypoint.sh armhf
	
build-x86_64:
	docker build -tag ${REPO}/cross-rs-gst:x86_64 --file docker/x86_64/Dockerfile .

docker-build:
	docker build --tag ${REPO}/${IMAGE} --file Dockerfile .

release: git-release docker-release

git-release:
	git diff-index --quiet HEAD || (echo "Git repo is unclean"; false)
	git tag -a "${IMAGE}/${VERSION}" -m "Release ${IMAGE}:${VERSION}"
	git push --follow-tags

docker-release:
	docker tag ${REPO}/${IMAGE}:${VERSION} ${REPO}/${IMAGE}:latest
	docker push ${REPO}/${IMAGE}:${VERSION}
	docker push ${REPO}/${IMAGE}:latest
