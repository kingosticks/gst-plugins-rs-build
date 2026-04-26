REPO = ghcr.io/mopidy
IMAGE = gst-plugins-rs-build
VERSION = $(shell cat VERSION)
WORKDIR = /src
PLUGIN = audio/spotify
ARCHES = armhf arm64 x86_64

ifdef GST_PLUGINS_RS_SRC
  GST_PLUGINS_RS_MOUNT := "-v ${GST_PLUGINS_RS_SRC}:${WORKDIR}/gst-plugins-rs:z"
endif

.PHONY: build docker-build release git-release docker-release

build: docker-build $(addprefix build-,$(ARCHES))

build-%:
	docker run ${GST_PLUGINS_RS_MOUNT} -v .:${WORKDIR}:z --workdir ${WORKDIR} -e GST_GIT_REPO -e GST_GIT_BRANCH ${REPO}/${IMAGE}:${VERSION}-$* /bin/bash entrypoint.sh $* ${PLUGIN}

docker-build: $(addprefix docker-build-,$(ARCHES))

docker-build-%:
	docker build --tag ${REPO}/${IMAGE}:${VERSION}-$* --file Dockerfile.$* .

release: git-release docker-release

git-release:
	git diff-index --quiet HEAD || (echo "Git repo is unclean"; false)
	git tag -a "${IMAGE}/${VERSION}" -m "Release ${IMAGE}:${VERSION}"
	git push --follow-tags

docker-release: $(addprefix docker-release-,$(ARCHES))

docker-release-%:
	docker tag ${REPO}/${IMAGE}:${VERSION}-$* ${REPO}/${IMAGE}:latest-$*
	docker push ${REPO}/${IMAGE}:${VERSION}-$*
	docker push ${REPO}/${IMAGE}:latest-$*
