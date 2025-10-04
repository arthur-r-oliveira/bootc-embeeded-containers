# Ansible Bootc Embedded Containers Makefile

.PHONY: help install build setup-registry push-registry export-registry import-registry-windows delta-updates deploy-delta test-vm clean

# Default target
help:
	@echo "Available targets (in recommended order):"
	@echo ""
	@echo "Step 1: Installation and setup"
	@echo "  install          - Install Ansible collections"
	@echo "  check            - Check Ansible syntax"
	@echo ""
	@echo "Step 2: Build base and embedded images"
	@echo "  build-v1         - Build base MicroShift image (v1)"
	@echo "  build-v2         - Build embedded image (v2)"
	@echo "  build-v3         - Build embedded image (v3)"
	@echo "  build            - Build all images (v1, v2, v3)"
	@echo ""
	@echo "Step 3: Setup registry (for disconnected deployments)"
	@echo "  setup-registry   - Setup OCI registry"
	@echo "  push-registry    - Push images to registry"
	@echo "  export-registry  - Export registry for transfer"
	@echo ""
	@echo "Step 4: Create delta updates (after building multiple versions)"
	@echo "  delta-updates    - Create delta updates between versions"
	@echo "  deploy-delta     - Deploy delta updates"
	@echo ""
	@echo "Step 5: Testing and deployment"
	@echo "  test-vm          - Create test VM"
	@echo "  complete         - Run complete workflow"
	@echo ""
	@echo "Registry Transfer (Cross-platform)"
	@echo "  import-registry-windows - Import registry on Windows"
	@echo "  complete-registry-workflow - Complete registry workflow"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean            - Clean build artifacts"

# Install Ansible collections
install:
	ansible-galaxy collection install -r requirements.yml

# Build all images
build:
	ansible-playbook playbooks/build-bootc-images.yml

# Build specific versions
build-v1:
	ansible-playbook playbooks/build-bootc-images.yml -e "build_tags=['v1']"

build-v2:
	ansible-playbook playbooks/build-bootc-images.yml -e "build_tags=['v2']"

build-v3:
	ansible-playbook playbooks/build-bootc-images.yml -e "build_tags=['v3']"

# Setup registry
setup-registry:
	ansible-playbook playbooks/setup-registry.yml

# Push images to registry
push-registry:
	ansible-playbook playbooks/push-to-registry.yml

# Export registry for transfer
export-registry:
	ansible-playbook playbooks/export-registry.yml

# Import registry on Windows
import-registry-windows:
	ansible-playbook playbooks/import-registry-windows.yml

# Complete registry workflow
complete-registry-workflow:
	ansible-playbook playbooks/complete-registry-workflow.yml

# Create delta updates
delta-updates:
	ansible-playbook playbooks/delta-updates.yml

# Deploy delta updates
deploy-delta:
	ansible-playbook playbooks/deploy-delta-update.yml

# Create test VM
test-vm:
	ansible-playbook playbooks/setup-registry.yml
	ansible-playbook -i inventory/local.yml playbooks/build-bootc-images.yml -e "build_tags=['v1']"

# Complete workflow
complete:
	ansible-playbook playbooks/complete-workflow.yml

# Clean build artifacts
clean:
	rm -rf /tmp/tar-diff
	rm -rf /tmp/go1.22.12.linux-amd64.tar.gz
	rm -rf /var/ostree/updates
	podman system prune -f

# Check Ansible syntax
check:
	ansible-playbook --syntax-check playbooks/build-bootc-images.yml
	ansible-playbook --syntax-check playbooks/setup-registry.yml
	ansible-playbook --syntax-check playbooks/delta-updates.yml
	ansible-playbook --syntax-check playbooks/deploy-delta-update.yml
	ansible-playbook --syntax-check playbooks/complete-workflow.yml

# Production deployment
prod-build:
	ansible-playbook -i inventory/production.yml playbooks/build-bootc-images.yml

prod-registry:
	ansible-playbook -i inventory/production.yml playbooks/setup-registry.yml

prod-delta:
	ansible-playbook -i inventory/production.yml playbooks/delta-updates.yml

prod-deploy:
	ansible-playbook -i inventory/production.yml playbooks/deploy-delta-update.yml