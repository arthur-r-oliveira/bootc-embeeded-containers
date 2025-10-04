# Ansible Bootc Embedded Containers

This Ansible implementation provides automated building and management of self-contained appliances with Red Hat Image Mode (bootc) within MicroShift for Kubernetes workloads. It replaces the manual shell scripts with a comprehensive, scalable automation solution.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Playbooks](#playbooks)
- [Roles](#roles)
- [Configuration](#configuration)
- [Delta Updates](#delta-updates)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Overview

This Ansible implementation automates the entire workflow for creating bootc-based self-contained appliances:

1. **Base Image Building**: Creates MicroShift base images with RHEL Image Mode
2. **Embedded Image Building**: Embeds application containers into bootc images
3. **ISO Creation**: Generates bootable ISOs for deployment
4. **Registry Management**: Sets up OCI registries for disconnected deployments
5. **Delta Updates**: Creates and deploys delta updates using tar-diff/tar-patch
6. **VM Testing**: Automated VM creation and testing

## Prerequisites

### System Requirements
- RHEL 9.4+ or Fedora 38+
- Ansible 2.15+
- Podman 4.0+
- QEMU/KVM for VM testing
- Go 1.22+ (for tar-diff compilation)

### Required Collections
```bash
ansible-galaxy collection install -r requirements.yml
```

### Red Hat Pull Secret
Download your `.pull-secret.json` from [Red Hat Console](https://console.redhat.com/openshift/downloads#tool-pull-secret) and place it in the project root.

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd bootc-embeeded-containers
   ```

2. **Install Ansible collections**:
   ```bash
   cd ansible
   ansible-galaxy collection install -r requirements.yml
   ```

3. **Configure inventory**:
   - Edit `inventory/local.yml` for local development
   - Edit `inventory/production.yml` for production deployment

4. **Place pull secret**:
   ```bash
   cp /path/to/your/.pull-secret.json ../.pull-secret.json
   ```

## Quick Start

### Local Development
```bash
cd ansible

# Step 1: Build base and embedded images
ansible-playbook playbooks/build-bootc-images.yml

# Step 2: Setup local registry (for disconnected deployments)
ansible-playbook playbooks/setup-registry.yml

# Step 3: Create delta updates (after building multiple versions)
ansible-playbook playbooks/delta-updates.yml

# Step 4: Deploy delta updates
ansible-playbook playbooks/deploy-delta-update.yml
```

### Production Deployment
```bash
cd ansible

# Step 1: Build images for production
ansible-playbook -i inventory/production.yml playbooks/build-bootc-images.yml

# Step 2: Setup production registry
ansible-playbook -i inventory/production.yml playbooks/setup-registry.yml

# Step 3: Create delta updates
ansible-playbook -i inventory/production.yml playbooks/delta-updates.yml

# Step 4: Deploy to target systems
ansible-playbook -i inventory/production.yml playbooks/deploy-delta-update.yml
```

## Playbooks

### 1. `build-bootc-images.yml`
Main playbook for building bootc images with embedded containers.

**Variables**:
- `build_tags`: List of image versions to build (e.g., ["v1", "v2", "v3"])
- `application_images`: List of container images to embed
- `microshift_config`: MicroShift and RHEL version configuration

**Usage**:
```bash
ansible-playbook playbooks/build-bootc-images.yml -e "build_tags=['v1','v2']"
```

### 2. `delta-updates.yml`
Creates delta updates between image versions using tar-diff.

**Variables**:
- `delta_config.base_image_tag`: Source image version
- `delta_config.updated_image_tag`: Target image version

**Usage**:
```bash
ansible-playbook playbooks/delta-updates.yml -e "base_image_tag=v1" -e "updated_image_tag=v2"
```

### 3. `setup-registry.yml`
Sets up OCI registry for disconnected deployments.

**Variables**:
- `registry_config.port`: Registry port (default: 5000)
- `registry_config.data_dir`: Registry data directory

### 4. `deploy-delta-update.yml`
Deploys delta updates to target systems.

**Variables**:
- `delta_deploy_config.base_image_tag`: Source image version
- `delta_deploy_config.updated_image_tag`: Target image version
- `delta_deploy_config.registry_url`: Target registry URL

### 5. `push-to-registry.yml`
Pushes bootc images to OCI registry.

**Variables**:
- `images_to_push`: List of images to push to registry

### 6. `export-registry.yml`
Exports registry data for cross-platform transfer.

**Variables**:
- `registry_export_config.export_dir`: Export directory
- `registry_export_config.transfer_package`: Transfer package filename

### 7. `import-registry-windows.yml`
Imports registry data on Windows systems.

**Variables**:
- `registry_import_config.data_dir`: Windows registry data directory
- `registry_import_config.registry_package`: Registry package path

### 8. `complete-registry-workflow.yml`
Complete registry workflow including export and transfer preparation.

## Roles

### `bootc_base_image`
Builds the base MicroShift bootc image with RHEL Image Mode.

**Tasks**:
- Creates build directories
- Generates Containerfile.base from template
- Builds base image with Podman
- Configures MicroShift, firewall, and security settings

### `bootc_embedded_image`
Builds embedded bootc images with application containers.

**Tasks**:
- Generates version-specific Containerfiles
- Copies embedding scripts and manifests
- Builds embedded images with application containers
- Supports multiple image versions (v1, v2, v3)

### `bootc_iso_creation`
Creates bootable ISOs from bootc images.

**Tasks**:
- Uses bootc-image-builder container
- Generates ISO files for deployment
- Places ISOs in output directory

### `oci_registry`
Sets up OCI registry for disconnected deployments.

**Tasks**:
- Installs Podman and related tools
- Configures registry authentication
- Starts registry container
- Sets up insecure registry configuration

### `bootc_delta_updates`
Creates delta updates using tar-diff/tar-patch.

**Tasks**:
- Installs Go and builds tar-diff/tar-patch
- Exports images to tar files
- Generates delta files
- Calculates compression ratios

### `bootc_delta_deployment`
Deploys delta updates to target systems.

**Tasks**:
- Installs tar-patch on target systems
- Reconstructs images from deltas
- Loads images to local registry
- Performs bootc switch and upgrade

### `bootc_vm_testing`
Creates and manages test VMs.

**Tasks**:
- Installs virtualization packages
- Creates isolated networks
- Generates kickstart files
- Creates and starts test VMs

### `registry_push`
Pushes bootc images to OCI registry.

**Tasks**:
- Verifies registry is running
- Logs into registry
- Tags images for registry
- Pushes images to registry
- Verifies push success

### `registry_export`
Exports registry data for cross-platform transfer.

**Tasks**:
- Stops registry container
- Compresses registry data
- Exports configuration files
- Creates import scripts
- Generates registry manifest
- Creates transfer package

### `registry_import_windows`
Imports registry data on Windows systems.

**Tasks**:
- Installs Podman Desktop
- Extracts registry data
- Starts registry container
- Tests registry connectivity
- Configures Windows firewall

## Configuration

### Global Variables
```yaml
bootc_config:
  pull_secret_file: ".pull-secret.json"
  base_image_name: "microshift-4.19-bootc"
  embedded_image_name: "microshift-4.19-bootc-embedded"
  build_dir: "/opt/bootc-builds"
  output_dir: "{{ build_dir }}/output"

microshift_config:
  version: "4.19"
  rhel_version: "9.6"
  user_password: "redhat02"

application_images:
  - "docker.io/library/wordpress:6.2.1-apache"
  - "docker.io/library/mysql:8.0"
```

### Inventory Configuration
- `inventory/local.yml`: Local development setup
- `inventory/production.yml`: Production deployment setup

## Delta Updates

The delta update system uses `tar-diff` and `tar-patch` to create efficient updates for bandwidth-constrained environments.

### Creating Delta Updates
```bash
ansible-playbook playbooks/delta-updates.yml \
  -e "base_image_tag=v1" \
  -e "updated_image_tag=v2"
```

### Deploying Delta Updates
```bash
ansible-playbook playbooks/deploy-delta-update.yml \
  -e "base_image_tag=v1" \
  -e "updated_image_tag=v2" \
  -e "registry_url=192.168.1.11:5000"
```

## Examples

### Complete Workflow
```bash
# 1. Build all images
ansible-playbook playbooks/build-bootc-images.yml

# 2. Setup registry
ansible-playbook playbooks/setup-registry.yml

# 3. Create delta updates
ansible-playbook playbooks/delta-updates.yml

# 4. Deploy to edge systems
ansible-playbook playbooks/deploy-delta-update.yml
```

### Custom Image Building
```bash
ansible-playbook playbooks/build-bootc-images.yml \
  -e "build_tags=['v1']" \
  -e "application_images=['docker.io/library/nginx:latest']"
```

### VM Testing
```bash
ansible-playbook playbooks/build-bootc-images.yml
ansible-playbook -i inventory/local.yml playbooks/setup-registry.yml
# VM will be created automatically with the latest image
```

## Troubleshooting

### Common Issues

1. **Pull Secret Not Found**:
   - Ensure `.pull-secret.json` is in the project root
   - Check file permissions (should be readable by Ansible)

2. **Registry Connection Issues**:
   - Verify registry is running: `podman ps | grep registry`
   - Check firewall settings for registry port
   - Verify insecure registry configuration

3. **Delta Update Failures**:
   - Ensure Go 1.22+ is installed
   - Check tar-diff/tar-patch compilation
   - Verify base and updated images exist

4. **VM Creation Issues**:
   - Check libvirt service status
   - Verify KVM support: `lsmod | grep kvm`
   - Check available disk space

### Debugging
```bash
# Enable verbose output
ansible-playbook playbooks/build-bootc-images.yml -vvv

# Check specific role
ansible-playbook playbooks/build-bootc-images.yml --tags bootc_base_image

# Test connectivity
ansible all -m ping -i inventory/production.yml
```

### Logs
- Build logs: `{{ bootc_config.build_dir }}/logs/`
- Registry logs: `journalctl -u podman-registry`
- VM logs: `virsh console {{ vm_config.vm_name }}`

## Migration from Shell Scripts

The original shell scripts are preserved and can be used alongside Ansible:

- `build-base.sh` → `bootc_base_image` role
- `build.sh` → `bootc_embedded_image` role
- `create-vm.sh` → `bootc_vm_testing` role
- `embed_image.sh` → Embedded in `bootc_embedded_image` role

Both approaches can coexist, allowing gradual migration or parallel usage based on requirements.