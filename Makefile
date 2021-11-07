PROJECT_ID=ticketing-devops-hamill
CLUSTER_NAME=ticketing

run-local:
	skaffold dev

###

check-env:
ifndef ENV
	$(error Please set ENV=[staging|prod])
endif

define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

###

GITHUB_SHA?=latest
LOCAL_TAG=$(IMAGE)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)
CONTAINER_NAME=$(IMAGE)

build:
	cd $(IMAGE) && docker build .

push:
# docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

deploy:
	kubectl rollout restart deployment $(IMAGE)-depl

###

tests:
	cd $(SERVICE_NAME) && npm install && npm run test:ci