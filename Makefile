REPO = ghcr.io/mopidy
IMAGE = gst-plugin-spotify-deb
VERSION = $(shell cat VERSION)

.PHONY: build release git-release docker-release

build:
	docker build -t ${REPO}/${IMAGE}:${VERSION} .

release: git-release docker-release

git-release:
	git diff-index --quiet HEAD || (echo "Git repo is unclean"; false)
	git tag -a "${IMAGE}/${VERSION}" -m "Release ${IMAGE}:${VERSION}"
	git push --follow-tags

docker-release:
	docker tag ${REPO}/${IMAGE}:${VERSION} ${REPO}/${IMAGE}:latest
	docker push ${REPO}/${IMAGE}:${VERSION}
	docker push ${REPO}/${IMAGE}:latest
