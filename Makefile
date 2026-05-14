.PHONY: help install-collections test build run clean deploy

IMAGE_NAME ?= wildfly-golden
IMAGE_TAG ?= latest
REGISTRY ?= ghcr.io/yourusername
CONTAINER_RUNTIME ?= docker

help:
	@echo "WildFly Golden Image - Make Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make install-collections    Install required Ansible collections"
	@echo ""
	@echo "Testing:"
	@echo "  make test                   Run Ansible playbook in check mode"
	@echo "  make test-verbose           Run with verbose output"
	@echo ""
	@echo "Building:"
	@echo "  make build                  Build the golden image with Docker"
	@echo ""
	@echo "Running:"
	@echo "  make run                    Run the container locally"
	@echo "  make stop                   Stop running containers"
	@echo "  make logs                   View container logs"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make k8s-deploy             Deploy to Kubernetes"
	@echo "  make k8s-undeploy           Remove from Kubernetes"
	@echo "  make k8s-status             Check deployment status"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                  Remove built images and containers"
	@echo ""
	@echo "Registry:"
	@echo "  make push                   Push image to registry"
	@echo "  make pull                   Pull image from registry"

install-collections:
	@echo "Installing Ansible collections..."
	ansible-galaxy collection install -r ansible/requirements.yml

test:
	@echo "Testing Ansible playbook (check mode)..."
	cd ansible && ansible-playbook -i inventory configure.yml --check

test-verbose:
	@echo "Testing Ansible playbook (verbose)..."
	cd ansible && ansible-playbook -i inventory configure.yml --check -vvv

build:
	@echo "Building image with Docker..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

run:
	@echo "Running container..."
	docker run -d \
		--name wildfly-golden-demo \
		-p 8080:8080 \
		-p 9990:9990 \
		-e DB_HOST=postgres \
		-e DB_NAME=mydb \
		-e DB_USER=admin \
		-e DB_PASSWORD=secret \
		$(IMAGE_NAME):$(IMAGE_TAG)
	@echo ""
	@echo "WildFly is starting..."
	@echo "HTTP: http://localhost:8080"
	@echo "Management: http://localhost:9990"
	@echo ""
	@echo "View logs: make logs"

stop:
	@echo "Stopping containers..."
	-docker stop wildfly-golden-demo
	-docker rm wildfly-golden-demo

logs:
	docker logs -f wildfly-golden-demo

clean: stop
	@echo "Cleaning up..."
	-docker rmi $(IMAGE_NAME):$(IMAGE_TAG)
	-docker system prune -f

k8s-create-secret:
	@echo "Creating Kubernetes secret..."
	kubectl create secret generic wildfly-db-secret \
		--from-literal=host=postgres.default.svc.cluster.local \
		--from-literal=database=mydb \
		--from-literal=username=wildfly \
		--from-literal=password=changeme \
		--dry-run=client -o yaml | kubectl apply -f -

k8s-deploy: k8s-create-secret
	@echo "Deploying to Kubernetes..."
	kubectl apply -f kubernetes/deployment.yml
	kubectl apply -f kubernetes/service.yml
	@echo ""
	@echo "Deployment started. Check status with: make k8s-status"

k8s-undeploy:
	@echo "Removing from Kubernetes..."
	-kubectl delete -f kubernetes/service.yml
	-kubectl delete -f kubernetes/deployment.yml
	-kubectl delete secret wildfly-db-secret

k8s-status:
	@echo "Deployment Status:"
	@echo ""
	kubectl get deployments -l app=wildfly
	@echo ""
	kubectl get pods -l app=wildfly
	@echo ""
	kubectl get services -l app=wildfly

k8s-logs:
	@echo "Fetching pod logs..."
	kubectl logs -l app=wildfly --tail=100 -f

k8s-port-forward:
	@echo "Port forwarding to localhost:8080..."
	kubectl port-forward svc/wildfly 8080:8080

push:
	@echo "Tagging and pushing image..."
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

pull:
	@echo "Pulling image from registry..."
	docker pull $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

validate:
	@echo "Validating Ansible syntax..."
	cd ansible && ansible-playbook configure.yml --syntax-check
	@echo ""
	@echo "Validating Kubernetes manifests..."
	kubectl apply --dry-run=client -f kubernetes/

health-check:
	@echo "Checking WildFly health..."
	@curl -sf http://localhost:8080 > /dev/null && echo "✅ HTTP endpoint OK" || echo "❌ HTTP endpoint failed"
	@curl -sf http://localhost:9990/management > /dev/null && echo "✅ Management interface OK" || echo "❌ Management interface failed"
