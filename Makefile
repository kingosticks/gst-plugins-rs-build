REPO = ghcr.io/mopidy
IMAGE = gst-plugins-rs-build
VERSION = $(shell cat images/VERSION)
PLUGIN ?= audio/spotify
ARCHES = amd64 arm64 armhf

ifdef GST_PLUGINS_RS_SRC
  GST_PLUGINS_RS_MOUNT := -v ${GST_PLUGINS_RS_SRC}:/build/gst-plugins-rs:z
endif

DOCKER_RUN = docker run --rm \
	-v ./package:/package:z,ro \
	-v ./build:/build:z \
	-v ./dist:/dist:z \
	${GST_PLUGINS_RS_MOUNT} \
	-e GST_GIT_REPO -e GST_GIT_BRANCH

.PHONY: build clean docker-image release git-release docker-release

# --- Packages ---

build: docker-image $(addprefix build-,$(ARCHES))

build-%:
	mkdir -p build dist
	${DOCKER_RUN} ${REPO}/${IMAGE}:${VERSION}-$* /bin/bash /package/build.sh $* ${PLUGIN}

clean:
	docker run --rm -v .:/repo debian:trixie-slim rm -rf /repo/build /repo/dist

# --- Images ---

docker-image: $(addprefix docker-image-,$(ARCHES))

docker-image-%:
	docker build --tag ${REPO}/${IMAGE}:${VERSION}-$* --file images/Dockerfile.$* images

# --- Release ---

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
