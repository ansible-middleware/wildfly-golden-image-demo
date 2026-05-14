# WildFly Golden Image Demo

Build production-ready, immutable WildFly container images using Ansible automation instead of complex, brittle Dockerfile RUN scripts.

## The Problem

Traditional Dockerfiles with complex bash scripts are:
- Hard to test without building the entire image
- Not idempotent (running twice might fail or create duplicates)
- Error-prone (bash escaping, timing issues, XML in heredocs)
- Difficult to debug (must rebuild from scratch)
- Not reusable (container-only, can't use for VMs)
- Lack validation (errors only appear at runtime)

## The Solution

Use Ansible to configure WildFly, then commit the configured container to a golden image:

```
Base Image → Ansible Configuration → Golden Image → Deployment
```

## Quick Start

### Prerequisites

- Docker
- Ansible (for local testing)
- Git

### Build Locally

```bash
# Clone the repository
git clone https://github.com/yourusername/wildfly-golden-image-demo.git
cd wildfly-golden-image-demo

# Build the golden image
docker build -t wildfly-golden:latest .
```

### Test Locally

```bash
# Run the container
docker run -d -p 8080:8080 -p 9990:9990 \
  -e DB_HOST=postgres \
  -e DB_NAME=mydb \
  -e DB_USER=admin \
  -e DB_PASSWORD=secret \
  wildfly-golden:latest

# Check WildFly is running
curl http://localhost:8080

# Access management console
curl http://localhost:9990/management
```

### Test Ansible Configuration (Without Building)

```bash
# Install required collections
ansible-galaxy collection install -r ansible/requirements.yml

# Run the playbook locally (requires root/sudo)
cd ansible
ansible-playbook -i inventory configure.yml --check

# Run for real
ansible-playbook -i inventory configure.yml
```

## Repository Structure

```
.
├── Dockerfile                 # Clean, minimal container definition
├── examples/
│   └── messy-dockerfile       # Anti-pattern example (what NOT to do)
├── ansible/
│   ├── configure.yml          # Main playbook
│   ├── requirements.yml       # Ansible collections needed
│   ├── inventory              # Localhost inventory
│   └── group_vars/
│       └── all.yml            # Configuration variables
├── .github/
│   └── workflows/
│       └── build-golden-image.yml  # CI/CD pipeline
├── kubernetes/
│   ├── deployment.yml         # K8s deployment manifest
│   └── service.yml            # K8s service manifest
└── docs/
    ├── ARCHITECTURE.md        # Detailed architecture
    └── DEMO_SCRIPT.md         # Presentation script
```

## Key Benefits

| Aspect | Dockerfile Approach | Ansible Approach |
|--------|-------------------|------------------|
| **Testability** | Must build entire image | Test locally without building |
| **Idempotency** | Often fails on re-run | Safe to run multiple times |
| **Debugging** | Rebuild from scratch | Test changes immediately |
| **Reusability** | Container only | Works for VMs, bare metal, containers |
| **Maintainability** | Bash spaghetti | Clean, declarative YAML |
| **Secret Management** | Often hardcoded | Injected at runtime |

## CI/CD Pipeline

The GitHub Actions workflow:

1. Builds a base container with Java and Ansible
2. Runs Ansible playbook inside the container
3. Commits the configured container to an image
4. Tests the golden image (health checks, smoke tests)
5. Pushes to container registry (GHCR, Quay, etc.)

See [`.github/workflows/build-golden-image.yml`](.github/workflows/build-golden-image.yml)

## Configuration

All configuration is in Ansible variables (`ansible/group_vars/all.yml`):

- WildFly version
- JVM tuning parameters
- JDBC drivers
- Datasources
- Clustering configuration
- Subsystem settings

## Deployment

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -f kubernetes/

# Check deployment
kubectl get pods -l app=wildfly

# Test the service
kubectl port-forward svc/wildfly 8080:8080
curl http://localhost:8080
```

### OpenShift

```bash
# Create a new app
oc new-app ghcr.io/yourusername/wildfly-golden:latest

# Expose the service
oc expose svc/wildfly-golden
```

## Customization

### Adding a New JDBC Driver

Edit `ansible/group_vars/all.yml`:

```yaml
jdbc_drivers:
  - name: org.postgresql
    version: '42.7.1'
    jar_file: postgresql-42.7.1.jar
    url: https://jdbc.postgresql.org/download/postgresql-42.7.1.jar
  - name: com.mysql         # Add MySQL
    version: '8.0.33'
    jar_file: mysql-connector-java-8.0.33.jar
    url: https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar
```

### Tuning JVM

Edit `ansible/group_vars/all.yml`:

```yaml
wildfly_java_opts:
  - '-Xms512m'
  - '-Xmx2048m'
  - '-XX:MetaspaceSize=256m'
  - '-XX:MaxMetaspaceSize=512m'
  - '-XX:+UseG1GC'           # Add G1 garbage collector
```

## Demo Presentation

See [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) for a step-by-step presentation guide.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## Resources

- [Ansible WildFly Collection](https://github.com/ansible-middleware/wildfly)
- [Buildah Documentation](https://buildah.io)
- [WildFly Documentation](https://docs.wildfly.org/)
- [GitHub Actions](https://docs.github.com/actions)

## License

Apache License 2.0

## Contact

Questions? Open an issue or reach out to [your contact info].
