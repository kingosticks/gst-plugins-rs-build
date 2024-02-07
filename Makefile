REPO = ghcr.io/mopidy
IMAGE = gst-plugins-rs-build
VERSION = $(shell cat VERSION)
WORKDIR = /gst-plugins-rs-build
PLUGIN = audio/spotify

ifdef GST_PLUGINS_RS_SRC
  GST_PLUGINS_RS_MOUNT := "-v ${GST_PLUGINS_RS_SRC}:${WORKDIR}/gst-plugins-rs:z"
endif

.PHONY: build release git-release docker-release

build: docker-build build-armhf build-arm64 build-x86_64

build-%:
	docker run ${GST_PLUGINS_RS_MOUNT} -v .:${WORKDIR}:z --workdir ${WORKDIR} ${REPO}/${IMAGE}:${VERSION} /bin/bash entrypoint.sh $* ${PLUGIN}
	
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
