# K9s Plugins - Modular Configuration

This directory contains modular K9s plugins, with each plugin in a separate YAML file.

## Directory Structure

```
~/.config/k9s/plugins/
├── trace-dns.yaml          # DNS tracing with Inspektor Gadget (Shift-T)
├── crd-wizard.yaml         # CRD management (Shift-W)
├── scale-zero.yaml         # Scale namespace to 0 replicas (Shift-Z)
├── debug.yaml              # Debug pods with netshoot (Shift-D)
├── krr.yaml                # Resource recommendations for workloads (Shift-K)
├── krr-ns.yaml             # Resource recommendations for namespaces (Shift-K)
├── holmesgpt.yaml          # AI-powered troubleshooting (Shift-H)
├── helm-diff-previous.yaml # Helm diff with previous revision (Shift-D)
└── helm-diff-current.yaml  # Helm diff with current values (Shift-D)
```

## Plugin File Format

Each plugin uses the snippet format (no `plugin:` wrapper):

```yaml
shortCut: Shift-X
description: My Plugin
scopes:
  - pods
  - deployments
command: bash
background: false
args:
  - -c
  - |
    echo "Running plugin for $NAME in $NAMESPACE"
```

## Management

**Add Plugin:** Create `~/.config/k9s/plugins/my-plugin.yaml` and restart k9s

**Edit Plugin:** Modify the file and restart k9s

**Disable Plugin:** Rename to `.disabled` extension or delete

**Share Plugin:** Copy the individual file

## Available Variables

- `$CONTEXT` - Kubernetes context
- `$CLUSTER` - Cluster name
- `$NAMESPACE` - Resource namespace
- `$NAME` - Resource name
- `$POD` - Pod name (container scope)
- `$CONTAINER` - Container name
- `$RESOURCE_NAME` - Resource type (e.g., 'deployments')
- `$KUBECONFIG` - Kubeconfig path
- `$COL-<column>` - Column values (e.g., `$COL-REVISION`)

## Resources

- [K9s Plugin Documentation](https://k9scli.io/topics/plugins/)
- [Plugin Examples](https://github.com/derailed/k9s/tree/master/plugins)
