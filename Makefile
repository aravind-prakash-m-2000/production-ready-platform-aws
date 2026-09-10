.PHONY: fmt validate kustomize test

fmt:
	terraform fmt -recursive terraform

validate-dev:
	cd terraform/environments/dev && terraform init -backend=false -input=false && terraform validate

validate-prod:
	cd terraform/environments/prod && terraform init -backend=false -input=false && terraform validate

kustomize:
	kustomize build kubernetes/overlays/dev >/dev/null
	kustomize build kubernetes/overlays/prod >/dev/null

test:
	python -m unittest discover -s apps/checkout-api -p 'test_*.py'
