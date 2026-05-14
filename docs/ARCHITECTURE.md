# Architecture Documentation

## Overview

This project demonstrates building production-ready WildFly container images using Ansible for configuration instead of complex bash scripts in Dockerfiles.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Workflow                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Developer commits code
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                       │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │Containerfile│  │   Ansible    │  │  GitHub Actions    │  │
│  │(minimal)    │  │  Playbooks   │  │  CI/CD Pipeline    │  │
│  └────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Trigger on push/PR
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions Build Pipeline                   │
│                                                              │
│  1. Create Base Container                                   │
│     ┌───────────────────────────────────────────────┐       │
│     │ FROM ubi9/ubi-minimal                         │       │
│     │ RUN install Java, Python, Ansible             │       │
│     └───────────────────────────────────────────────┘       │
│                            │                                 │
│  2. Install Ansible Collections                             │
│     ┌───────────────────────────────────────────────┐       │
│     │ ansible-galaxy collection install             │       │
│     │   - middleware_automation.wildfly             │       │
│     └───────────────────────────────────────────────┘       │
│                            │                                 │
│  3. Run Ansible Configuration                               │
│     ┌───────────────────────────────────────────────┐       │
│     │ ansible-playbook configure.yml                │       │
│     │   - Install WildFly                           │       │
│     │   - Configure JDBC drivers                    │       │
│     │   - Setup datasources                         │       │
│     │   - Tune JVM                                  │       │
│     │   - Configure subsystems                      │       │
│     │   - Validate installation                     │       │
│     └───────────────────────────────────────────────┘       │
│                            │                                 │
│  4. Commit to Golden Image                                  │
│     ┌───────────────────────────────────────────────┐       │
│     │ buildah commit → wildfly-golden:latest        │       │
│     └───────────────────────────────────────────────┘       │
│                            │                                 │
│  5. Test Golden Image                                       │
│     ┌───────────────────────────────────────────────┐       │
│     │ - Start container                             │       │
│     │ - HTTP endpoint check                         │       │
│     │ - Management interface check                  │       │
│     │ - Configuration validation                    │       │
│     └───────────────────────────────────────────────┘       │
│                            │                                 │
│  6. Push to Registry                                        │
│     ┌───────────────────────────────────────────────┐       │
│     │ buildah push ghcr.io/org/wildfly-golden       │       │
│     │   - Tag: latest                               │       │
│     │   - Tag: YYYYMMDD-{sha}                       │       │
│     └───────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Image published
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Container Registry (GHCR)                       │
│                                                              │
│  ghcr.io/org/wildfly-golden:latest                          │
│  ghcr.io/org/wildfly-golden:20260514-a1b2c3d                │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Pull and deploy
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              WildFly Deployment                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │ WildFly  │  │ WildFly  │  │ WildFly  │          │   │
│  │  │  Pod 1   │  │  Pod 2   │  │  Pod 3   │          │   │
│  │  └──────────┘  └──────────┘  └──────────┘          │   │
│  │       │              │              │                │   │
│  │       └──────────────┴──────────────┘                │   │
│  │                      │                               │   │
│  │                  Service                             │   │
│  │            (ClusterIP: wildfly)                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          │                                   │
│                      Ingress                                 │
│              (wildfly.example.com)                           │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Containerfile

**Purpose**: Minimal container definition that delegates configuration to Ansible.

**Responsibilities**:
- Install base dependencies (Java, Python, Ansible)
- Copy Ansible files into the container
- Execute Ansible playbook
- Set runtime configuration (user, ports, CMD)

**Benefits**:
- Clean and maintainable
- No complex bash scripts
- Easy to understand and modify

### 2. Ansible Configuration

**Structure**:
```
ansible/
├── configure.yml           # Main playbook
├── requirements.yml        # Required Ansible collections
├── inventory              # Localhost inventory
└── group_vars/
    └── all.yml            # Configuration variables
```

**Responsibilities**:
- Install WildFly
- Configure JDBC drivers
- Setup datasources
- Tune JVM parameters
- Configure subsystems (clustering, web, transactions)
- Validate installation

**Benefits**:
- Declarative configuration
- Idempotent operations
- Testable locally
- Reusable across environments

### 3. GitHub Actions CI/CD

**Pipeline Stages**:

1. **Build Base Image**: Create container with Java and Ansible
2. **Install Collections**: Add required Ansible collections
3. **Configure**: Run Ansible playbook
4. **Commit**: Save configured container as image
5. **Test**: Validate the golden image
6. **Push**: Publish to container registry

**Testing Includes**:
- HTTP endpoint health check
- Management interface validation
- Configuration verification
- User and permission checks

### 4. Kubernetes Deployment

**Components**:
- **Deployment**: Manages WildFly pod replicas
- **Service**: Exposes WildFly on cluster network
- **Secret**: Stores database credentials
- **Ingress**: External access with TLS

**Runtime Configuration**:
- Database credentials injected via secrets
- JVM settings via environment variables
- Health checks (liveness, readiness, startup)
- Resource limits (CPU, memory)

## Configuration Flow

### Build Time (Immutable)

These settings are baked into the golden image:

1. **WildFly Version**: Determined by `wildfly_version` variable
2. **JDBC Drivers**: Downloaded and installed modules
3. **JVM Base Settings**: Default heap sizes and GC configuration
4. **Subsystem Defaults**: Clustering, transaction settings
5. **User/Group**: `wildfly` user created

### Runtime (Dynamic)

These settings are injected at deployment:

1. **Database Connection**: Host, port, database name, credentials
2. **JVM Overrides**: Additional Java options via `JAVA_OPTS`
3. **Node Identity**: Hostname, cluster identifier
4. **Environment-Specific**: Dev/staging/prod differences

## Security Architecture

### Secret Management

**Never in Image**:
- Database passwords
- API keys
- TLS certificates
- Admin credentials

**Injected at Runtime**:
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: wildfly-db-secret
      key: password
```

### Image Security

**Scanning**:
- Trivy for vulnerability detection
- Grype for additional scanning
- Policy enforcement in CI/CD

**Runtime Security**:
- Non-root user (wildfly)
- Minimal base image (UBI9)
- No unnecessary packages
- Read-only root filesystem (optional)

## Scaling Architecture

### Horizontal Scaling

```bash
# Scale to 5 replicas
kubectl scale deployment wildfly-golden --replicas=5
```

**Clustering**:
- JGroups configured for TCP-based discovery
- Session replication enabled
- Shared state via external cache (optional)

### Vertical Scaling

Adjust resource limits:
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "4000m"
```

## Monitoring and Observability

### Health Checks

**Startup Probe**: Allows longer startup time
**Liveness Probe**: Detects crashed containers
**Readiness Probe**: Controls traffic routing

### Metrics

**WildFly Management API**:
- Thread pool statistics
- Datasource pool metrics
- JVM memory usage
- Request statistics

**Integration Points**:
- Prometheus metrics export
- Grafana dashboards
- ELK/EFK for logging
- Jaeger for tracing

## Disaster Recovery

### Image Versioning

**Strategy**:
```
ghcr.io/org/wildfly-golden:latest          # Always current
ghcr.io/org/wildfly-golden:20260514-a1b2c3d  # Specific version
```

**Rollback**:
```bash
# Rollback to previous version
kubectl rollout undo deployment/wildfly-golden

# Rollback to specific revision
kubectl rollout undo deployment/wildfly-golden --to-revision=3
```

### Backup

**Configuration**: Version controlled in Git
**Data**: External databases with separate backup strategy
**Logs**: Centralized logging system

## Performance Considerations

### Build Optimization

**Layer Caching**:
- Base image cached
- Dependencies cached (Ansible collections)
- Only playbook re-runs on config changes

**Build Time**:
- Base build: ~6 minutes
- Config change rebuild: ~2 minutes

### Runtime Optimization

**JVM Tuning**:
```yaml
wildfly_java_opts:
  - '-XX:+UseG1GC'              # Efficient GC
  - '-XX:MaxGCPauseMillis=200'  # Low latency target
  - '-Xms512m'                   # Initial heap
  - '-Xmx2048m'                  # Max heap
```

**Connection Pooling**:
- Database pools pre-configured
- Optimal pool sizes per workload
- Connection validation enabled

## Extensibility

### Adding New Features

1. **Update Ansible Variables**: Edit `group_vars/all.yml`
2. **Test Locally**: Run playbook on test system
3. **Commit Changes**: Push to repository
4. **CI/CD Builds**: Automated build and test
5. **Deploy**: New image available

### Custom Modules

Add custom Ansible modules for:
- Application-specific configuration
- Integration with external services
- Advanced monitoring setup

### Multi-App Servers

Adapt for other platforms:
- Tomcat: Use `middleware_automation.tomcat`
- JBoss EAP: Use `middleware_automation.jboss_eap`
- Custom apps: Write custom roles

## Comparison: Before vs. After

| Aspect | Dockerfile Approach | Ansible Approach |
|--------|-------------------|------------------|
| **Configuration** | Bash scripts in RUN | Declarative YAML |
| **Testing** | Build required | Local playbook run |
| **Debugging** | Rebuild from scratch | Immediate feedback |
| **Idempotency** | Often fails | Guaranteed |
| **Reusability** | Container only | VMs, bare metal, containers |
| **Secrets** | Often hardcoded | Runtime injection |
| **Validation** | Runtime errors | Pre-build validation |
| **Maintenance** | Difficult | Easy |
| **Collaboration** | Limited | Code review friendly |

## Future Enhancements

### Planned Features

1. **Multi-Stage Builds**: Separate build and runtime images
2. **Security Scanning**: Integrate Snyk or Anchore
3. **Performance Testing**: Automated load testing in CI/CD
4. **Blue/Green Deployments**: Zero-downtime updates
5. **Canary Deployments**: Progressive rollouts
6. **Auto-Scaling**: HPA based on metrics
7. **Cost Optimization**: Right-sizing recommendations

### Community Contributions

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.
