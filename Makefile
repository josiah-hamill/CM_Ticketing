PROJECT_ID=ticketing-devops-hamill
CLUSTER_NAME=ticketing

run-local:
	skaffold dev

###

create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform

###

check-env:
ifndef ENV
	$(error Please set ENV=[staging|prod])
endif

define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

###

terraform-create-workspace: check-env
	cd terraform/terraform-provision-lb && \
		terraform workspace new $(ENV)

terraform-init: check-env
	cd terraform/terraform-provision-gcp-cluster && \
		terraform workspace select $(ENV) && \
		terraform init

TF_ACTION?=plan

terraform-cluster-action: check-env
	cd terraform/terraform-provision-gcp-cluster && \
		terraform workspace select $(ENV) && \
		terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars" \
		-var="cloudflare_api_token=$(call get-secret,cloudflare_api_token)"

terraform-lb-action: check-env
	cd terraform/terraform-provision-lb && \
		terraform workspace select $(ENV) && \
		terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars" \
		-var="jwt_key=$(call get-secret,jwt_key)" \
		-var="stripe_key=$(call get-secret,stripe_key)"

# GITHUB_SHA?=latest
LOCAL_TAG=$(IMAGE)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)
CONTAINER_NAME=$(IMAGE)

build:
	cd $(IMAGE) && docker build -t $(LOCAL_TAG) .

push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

deploy:
	kubectl rollout restart deployment $(IMAGE)-depl

###

tests:
	cd $(SERVICE_NAME) && npm install && npm run test:ci