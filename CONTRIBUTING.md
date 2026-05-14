# Contributing to WildFly Golden Image Demo

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Code of Conduct

This project adheres to the Contributor Covenant code of conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**:
  - OS and version
  - Docker version
  - Ansible version
  - Kubernetes version (if applicable)
- **Logs**: Relevant log output

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title** and description
- **Use case**: Explain why this enhancement would be useful
- **Examples**: Provide examples of how it would work
- **Alternatives**: Any alternative solutions you've considered

### Pull Requests

1. **Fork the Repository**
   ```bash
   git clone https://github.com/yourusername/wildfly-golden-image-demo.git
   cd wildfly-golden-image-demo
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make Your Changes**
   - Follow the coding standards (see below)
   - Add or update tests as needed
   - Update documentation if needed

4. **Test Your Changes**
   ```bash
   # Test Ansible playbook
   make test

   # Build the image
   make build

   # Run locally
   make run

   # Check it works
   make health-check
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add new JDBC driver support"
   ```

   Use conventional commit messages:
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `test:` Adding or updating tests
   - `refactor:` Code refactoring
   - `chore:` Maintenance tasks

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a Pull Request on GitHub.

## Development Guidelines

### Ansible Playbooks

- **Idempotency**: All tasks must be idempotent
- **Documentation**: Add comments for complex tasks
- **Variables**: Use variables instead of hardcoded values
- **Validation**: Include validation tasks where appropriate
- **Handlers**: Use handlers for service restarts
- **Tags**: Add tags to allow selective task execution

Example:
```yaml
- name: Configure datasource
  middleware_automation.wildfly.wildfly_datasource:
    name: "{{ item.name }}"
    jndi_name: "{{ item.jndi_name }}"
    driver: "{{ item.driver }}"
  loop: "{{ wildfly_datasources }}"
  tags:
    - datasource
    - configuration
```

### Container Best Practices

- **Minimal Layers**: Combine RUN commands where possible
- **No Secrets**: Never include secrets in images
- **Non-Root User**: Always run as non-root
- **Labels**: Include OCI labels for metadata
- **Size Optimization**: Clean up caches and temp files

### Kubernetes Manifests

- **Resource Limits**: Always specify limits and requests
- **Health Checks**: Include liveness and readiness probes
- **Labels**: Use consistent labeling
- **Secrets**: Use Kubernetes secrets, never hardcoded values
- **Namespacing**: Support namespace customization

### Documentation

- **README**: Update if adding new features
- **Comments**: Add inline comments for complex logic
- **Examples**: Provide usage examples
- **Architecture**: Update architecture docs for significant changes

## Testing Requirements

### Local Testing

Before submitting a PR:

1. **Syntax Check**
   ```bash
   make validate
   ```

2. **Ansible Check Mode**
   ```bash
   make test
   ```

3. **Build Test**
   ```bash
   make build
   ```

4. **Runtime Test**
   ```bash
   make run
   make health-check
   ```

5. **Kubernetes Test** (if applicable)
   ```bash
   make k8s-deploy
   make k8s-status
   ```

### CI/CD

Pull requests automatically trigger:
- Ansible syntax validation
- Container image build
- Automated testing
- Security scanning (future)

## Project Structure

```
.
├── Containerfile              # Main container definition
├── Makefile                   # Build and test commands
├── ansible/
│   ├── configure.yml          # Main playbook
│   ├── requirements.yml       # Ansible collections
│   ├── inventory              # Inventory file
│   └── group_vars/
│       └── all.yml            # Configuration variables
├── .github/
│   └── workflows/
│       └── build-golden-image.yml  # CI/CD pipeline
├── kubernetes/                # K8s manifests
├── examples/                  # Example files
└── docs/                      # Documentation
```

## Style Guidelines

### Ansible

- Use 2 spaces for indentation
- Quote strings when needed
- Use YAML full syntax (not short form)
- Name all tasks descriptively
- Use `ansible.builtin.*` for built-in modules

### YAML

- Use 2 spaces for indentation
- No tabs
- Quote strings with special characters
- Use `---` at the beginning of files

### Markdown

- Use ATX-style headers (`#`)
- One blank line between sections
- Code blocks with language specification
- Lists with `-` for unordered, `1.` for ordered

## Adding New Features

### Adding a New JDBC Driver

1. Update `ansible/group_vars/all.yml`:
   ```yaml
   jdbc_drivers:
     - name: com.mysql
       version: '8.0.33'
       jar_file: mysql-connector-java-8.0.33.jar
       url: https://repo1.maven.org/.../mysql-connector-java-8.0.33.jar
   ```

2. Test locally:
   ```bash
   make test
   ```

3. Build and verify:
   ```bash
   make build
   make run
   ```

### Adding a New Configuration Option

1. Add variable to `group_vars/all.yml`
2. Update playbook to use the variable
3. Document in README
4. Add example usage
5. Test thoroughly

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create git tag
4. Push tag to trigger release workflow
5. Publish release notes

## Getting Help

- **GitHub Issues**: For bugs and feature requests
- **Discussions**: For questions and ideas
- **Email**: [maintainer email]

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes
- CONTRIBUTORS.md file

Thank you for contributing!
