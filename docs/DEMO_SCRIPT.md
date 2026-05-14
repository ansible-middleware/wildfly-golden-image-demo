# Demo Presentation Script

This is a step-by-step guide for presenting the "Building Golden Container Images: Ansible vs. Messy Dockerfiles" demo.

## Setup (Before the Demo)

### Prerequisites
- Clone the repository
- Have a terminal ready with split panes
- Have the GitHub repository open in a browser
- Have a Kubernetes cluster available (or use Kind/Minikube)
- Pre-install: buildah, podman, kubectl, ansible

### Pre-Demo Checklist
- [ ] Clear terminal history
- [ ] Ensure GitHub Actions workflow is enabled
- [ ] Have example messy Dockerfile open in editor
- [ ] Have clean Dockerfile and Ansible playbook ready
- [ ] Test build locally at least once

## Demo Flow (15-20 minutes)

### Part 1: The Problem - Messy Dockerfiles (5 min)

**Script:**
"Let me show you a common pattern I see in production environments..."

**Actions:**
1. Open `examples/messy-dockerfile`
2. Scroll through slowly, highlighting problems

**Key Points to Make:**
- "Look at this RUN command with bash scripts and sleep commands"
- "See these hardcoded secrets? They're baked into the image"
- "This XML in a heredoc inside bash - imagine debugging this"
- "The sleep 10 - what if the server takes 11 seconds?"

**Ask the Audience:**
"How many of you have seen Dockerfiles like this?"
(Expect hands to go up)

"What happens when this fails to build at 90%?"
(Answer: Start from scratch)

---

### Part 2: The Solution - Ansible Approach (5 min)

**Script:**
"Now let's look at a better approach using Ansible..."

**Actions:**
1. Show the clean `Dockerfile`
2. Open `ansible/configure.yml`
3. Open `ansible/group_vars/all.yml`

**Key Points:**
```bash
# Show the Dockerfile
cat Dockerfile
```

"Notice how simple this is:
- Install Java and Ansible
- Copy Ansible files
- Run the playbook
- Done!"

```bash
# Show the playbook
cat ansible/configure.yml
```

"This is declarative configuration:
- Readable YAML instead of bash
- Idempotent - safe to run multiple times
- Testable - can run on any system"

```bash
# Show the variables
cat ansible/group_vars/all.yml
```

"All configuration in one place:
- JVM tuning
- JDBC drivers
- Datasources
- No secrets baked in!"

---

### Part 3: Testing Locally (3 min)

**Script:**
"The magic of this approach is we can test WITHOUT building a container..."

**Actions:**
```bash
# Install collections
cd ansible
ansible-galaxy collection install -r requirements.yml

# Run in check mode (dry run)
ansible-playbook -i inventory configure.yml --check

# Show what would change
ansible-playbook -i inventory configure.yml --diff --check
```

**Key Points:**
- "This runs locally on my machine"
- "I can see exactly what would change"
- "No container build required"
- "Same playbook works on VMs, bare metal, containers"

---

### Part 4: Building the Golden Image (4 min)

**Script:**
"Now let's build the actual golden image..."

**Actions:**
```bash
# Build the image
cd ..
docker build -t wildfly-golden:demo .
```

While building, explain:
- "Ansible is installing WildFly"
- "Configuring JDBC drivers"
- "Setting up datasources"
- "Applying JVM tuning"
- "All declaratively defined"

```bash
# Test the image
docker run -d -p 8080:8080 -p 9990:9990 \
  -e DB_HOST=postgres \
  -e DB_NAME=mydb \
  -e DB_USER=admin \
  -e DB_PASSWORD=secret \
  wildfly-golden:demo

# Check it's running
curl http://localhost:8080

# Show logs
docker logs -f <container-id>
```

**Key Points:**
- "See how secrets are passed at runtime?"
- "No secrets in the image"
- "WildFly starts immediately - already configured"

---

### Part 5: CI/CD Pipeline (3 min)

**Script:**
"In production, this is fully automated with GitHub Actions..."

**Actions:**
1. Open `.github/workflows/build-golden-image.yml` in browser
2. Make a small change to trigger the workflow:

```bash
# Edit a config value
vim ansible/group_vars/all.yml
# Change max_pool_size from 25 to 30

git add .
git commit -m "Increase database pool size"
git push
```

3. Show GitHub Actions running:
   - Building base image
   - Running Ansible
   - Testing the image
   - Pushing to registry

**Key Points:**
- "Every change is tested automatically"
- "Image is built, tested, and published"
- "Version tagged automatically"
- "Failed builds don't push bad images"

---

### Part 6: Deploying to Kubernetes (3 min)

**Script:**
"Finally, let's deploy this to Kubernetes..."

**Actions:**
```bash
# Show Kubernetes manifests
cat kubernetes/deployment.yml
cat kubernetes/service.yml

# Create secret (use template)
kubectl create secret generic wildfly-db-secret \
  --from-literal=host=postgres.svc.cluster.local \
  --from-literal=database=mydb \
  --from-literal=username=wildfly \
  --from-literal=password=supersecret

# Deploy
kubectl apply -f kubernetes/

# Watch it come up
kubectl get pods -l app=wildfly -w

# Check the deployment
kubectl get all -l app=wildfly

# Test the service
kubectl port-forward svc/wildfly 8080:8080 &
curl http://localhost:8080
```

**Key Points:**
- "Zero configuration needed in pods"
- "Secrets injected at runtime"
- "Same image, different environments"
- "Scaling is just changing replica count"

---

## Wrap-Up (2 min)

**Script:**
"Let's recap what we've seen today..."

**Key Takeaways:**
1. **Dockerfile RUN scripts are an anti-pattern** for complex configuration
2. **Ansible makes images testable** before building
3. **Golden images simplify deployment** - everything is pre-configured
4. **Same tooling everywhere** - VMs, containers, bare metal
5. **CI/CD integration is straightforward** with this approach
6. **Configuration as code** enables review and version control

**Call to Action:**
- "Repository is available at: [your-repo-url]"
- "Try it with your own application server"
- "Ansible collections available for Tomcat, JBoss EAP, and more"

---

## Q&A Topics to Prepare For

### Expected Questions:

**Q: What about build time? Isn't Ansible slower?**
A: Actually faster! Ansible is more efficient than running shell scripts. Plus, layers are cached, so rebuilds are quick.

**Q: Can I still use multi-stage builds?**
A: Absolutely! Use one stage for Ansible configuration, then copy to a minimal runtime image.

**Q: What about secrets management?**
A: Notice how secrets are NEVER in the image. They're injected at runtime via env vars, Kubernetes secrets, or Vault.

**Q: Does this work with other app servers?**
A: Yes! There are Ansible collections for Tomcat, JBoss EAP, Apache HTTPD, and more.

**Q: What if I need different configs for dev/staging/prod?**
A: Use Ansible's inventory and group_vars to manage environment-specific configuration.

**Q: How do I debug if something goes wrong?**
A: Run the playbook locally with `-vvv` for verbose output. You can also use `--step` to run one task at a time.

**Q: Can I test this in my environment?**
A: Yes! The playbook works on any system. Test on a VM first, then build the container.

---

## Timing Breakdown

| Section | Time | Running Total |
|---------|------|---------------|
| Problem (Messy Dockerfile) | 5 min | 5 min |
| Solution (Ansible) | 5 min | 10 min |
| Local Testing | 3 min | 13 min |
| Building Image | 4 min | 17 min |
| CI/CD Pipeline | 3 min | 20 min |
| Kubernetes Deployment | 3 min | 23 min |
| Wrap-up | 2 min | 25 min |

## Backup Demos (If Time Permits)

### Show Configuration Validation
```bash
# Use Ansible's --syntax-check
ansible-playbook configure.yml --syntax-check

# Use --diff to show changes
ansible-playbook configure.yml --diff --check
```

### Show Image Scanning
```bash
# Scan with Trivy
trivy image wildfly-golden:demo

# Show there are no high/critical vulns
```

### Show Multi-Environment Setup
```bash
# Different configs for different environments
ls ansible/group_vars/
# dev.yml, staging.yml, prod.yml
```
