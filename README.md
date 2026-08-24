# AgentOps

**Guardrailed AI remediation for Kubernetes incidents.**

AgentOps is an MCP-based operations layer that gives AI coding agents controlled access to Kubernetes, ArgoCD, Prometheus and GitOps workflows.

It is built on top of **[ClusterCore](https://github.com/mazin1hn/eks)**, a production-grade, end-to-end GitOps-driven Kubernetes Platform I built on Amazon EKS.

Instead of giving an AI agent unrestricted production access, AgentOps allows it to investigate incidents, correlate operational evidence, propose remediations, validate changes and prepare a Git commit — while keeping production changes behind deterministic policy checks, CI and human approval.

---

## Architecture

```text
                         ┌──────────────────┐
                         │     Engineer     │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │   Claude Code    │
                         │    AI Agent      │
                         └────────┬─────────┘
                                  │
                                  │ MCP
                                  ▼
                    ┌──────────────────────────┐
                    │    AgentOps MCP Server   │
                    └────────────┬─────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
        ┌──────────┐       ┌──────────┐       ┌───────────┐
        │  ArgoCD  │       │Kubernetes│       │Prometheus │
        └────┬─────┘       └────┬─────┘       └──────┬────┘
             │                  │                    │
             └──────────────────┼────────────────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │ Incident Correlation│
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │ Proposed Remediation│
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │ Policy + Helm       │
                     │ Validation          │
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │ Local Git Branch +  │
                     │ Commit              │
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │  HUMAN APPROVAL     │
                     └──────────┬──────────┘
                                │
                                ▼
                         Pull Request
                                │
                                ▼
                         CI Validation
                                │
                                ▼
                              Merge
                                │
                                ▼
                         ArgoCD Reconcile
                                │
                                ▼
                              EKS
```

---

## Why AgentOps?

AI agents are increasingly capable of reasoning about infrastructure and diagnosing operational failures.

The dangerous part is what happens next.

Giving an autonomous agent unrestricted Kubernetes or cloud credentials means an incorrect diagnosis could become an incorrect production change.

AgentOps explores a different model:

> **Give the agent enough access to investigate and prepare a remediation, but keep production changes behind deterministic guardrails and human approval.**

The agent can reason.

The control plane decides what it is allowed to do.

---

## What AgentOps Can Do

| Capability | Supported |
|---|:---:|
| Inspect ArgoCD application health | ✅ |
| Inspect Kubernetes pods | ✅ |
| Read Kubernetes events | ✅ |
| Read container logs | ✅ |
| Query Prometheus metrics | ✅ |
| Correlate incident evidence | ✅ |
| Identify unhealthy workloads | ✅ |
| Propose constrained remediation | ✅ |
| Validate remediation policy | ✅ |
| Run Helm lint validation | ✅ |
| Render Helm templates | ✅ |
| Prepare a local Git branch | ✅ |
| Prepare a local remediation commit | ✅ |
| Directly mutate Kubernetes | ❌ |
| Automatically merge changes | ❌ |
| Automatically deploy to production | ❌ |

---

# Demo: Diagnosing a Broken Kubernetes Readiness Probe

The end-to-end demo runs against a real application deployed to Amazon EKS and managed through ArgoCD.

A controlled failure is introduced through Git.

## 1. Introduce the Incident

The application container listens on port `80`:

```yaml
containers:
  - name: eks-game
    ports:
      - containerPort: 80
```

A bad GitOps change configures its readiness probe to use port `9999`:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 9999
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

ArgoCD reconciles the desired state.

The containers themselves start successfully, but Kubernetes cannot mark the new pods as ready.

---

## 2. Runtime Symptoms

ArgoCD reports the application as:

```text
Sync Status:   Synced
Health Status: Progressing
```

The distinction is important.

The cluster successfully matches the desired Git state, so the application is **Synced**.

However, the desired configuration itself is broken, so the application remains **Progressing**.

Kubernetes reports:

```text
Readiness probe failed:
Get "http://<pod-ip>:9999/":
dial tcp <pod-ip>:9999:
connect: connection refused
```

Meanwhile, the affected containers remain running with:

```text
restart_count: 0
```

This tells us the application process itself is not repeatedly crashing.

The failure is in the readiness configuration.

---

## 3. Agent Investigation

The AI agent is given a natural-language incident:

```text
Investigate why eks-app in namespace eks-app is unhealthy.

Do not make any direct infrastructure or production changes.

Use the AgentOps MCP tools to gather evidence, determine the root
cause, propose and validate a remediation, and prepare the remediation
in Git if it is safe to do so.

Stop before any push, pull request, merge, ArgoCD sync, or direct
Kubernetes mutation.
```

The agent uses the AgentOps MCP interface to gather and correlate evidence.

```text
ArgoCD
   │
   └── Application: Synced / Progressing
                         │
                         ▼
Kubernetes
   │
   └── Replacement pods are unready
                         │
                         ▼
Events
   │
   └── Readiness probe connection refused :9999
                         │
                         ▼
Containers
   │
   └── Running / 0 restarts
                         │
                         ▼
Git
   │
   └── Readiness probe changed 80 → 9999
                         │
                         ▼
                    Root Cause
```

The investigation identifies the readiness probe configuration as the failure.

---

## 4. Proposed Remediation

AgentOps proposes the minimal change:

```diff
 readinessProbe:
   httpGet:
     path: /
-    port: 9999
+    port: 80
```

The proposal stage does **not** modify the live cluster.

It returns a reviewable diff describing the intended remediation.

---

## 5. Validation

Before AgentOps is allowed to prepare the Git remediation, the proposed change passes deterministic validation.

Example result:

```text
Policy checks       PASS
helm lint           PASS
helm template       PASS
Production changed  false
```

This means the agent's reasoning alone is not trusted as sufficient evidence that a change is safe.

The proposed change must also satisfy machine-enforced policy.

---

## 6. Local Git Remediation

After validation succeeds, AgentOps prepares the remediation locally.

Example:

```text
Branch:
agent/readiness-port-80

Commit:
fix: set readiness probe port to 80
```

The resulting state is:

```text
prepared: true
pushed: false
pull_request_created: false
production_changed: false
```

And the workflow stops.

---

# Human Approval Boundary

This is the central safety boundary in AgentOps.

```text
AI Investigation
      │
      ▼
AI Diagnosis
      │
      ▼
AI Proposal
      │
      ▼
Deterministic Validation
      │
      ▼
Local Git Commit
      │
      ▼
┌──────────────────────────┐
│      HUMAN APPROVAL      │
└──────────────────────────┘
      │
      ▼
Pull Request
      │
      ▼
CI
      │
      ▼
Merge
      │
      ▼
ArgoCD
      │
      ▼
EKS
```

The AI agent can prepare the remediation.

It cannot silently turn its own diagnosis into a production deployment.

---

# MCP Tooling

AgentOps exposes narrow operational capabilities through an MCP server rather than giving the agent unrestricted infrastructure access.

The core remediation workflow is:

```text
investigate_app
       │
       ▼
propose_readiness_fix
       │
       ▼
validate_readiness_fix
       │
       ▼
prepare_readiness_remediation
       │
       ▼
  HUMAN APPROVAL
```

## `investigate_app`

Collects operational evidence for an application.

This includes signals from:

- ArgoCD
- Kubernetes pod state
- container readiness
- Kubernetes events
- container logs
- Prometheus

It produces a correlated incident summary rather than requiring the agent to reason from unrelated raw commands.

Example:

```text
overall_status: NeedsAttention

argocd:
  sync_status: Synced
  health_status: Progressing

pods:
  total: 12
  healthy: 7
  unhealthy: 5

issues:
  - ArgoCD application health is Progressing
  - 5 unhealthy pods detected
```

---

## `propose_readiness_fix`

Creates a constrained remediation proposal for the readiness probe.

Example:

```text
change_type: readiness_probe_port

current_port: 9999
proposed_port: 80

action: proposal_only

requires_validation: true
requires_human_approval: true
```

No production change occurs during proposal generation.

---

## `validate_readiness_fix`

Validates the proposed configuration before a Git change can be prepared.

Validation includes:

```text
Input policy
    │
    ▼
Temporary chart mutation
    │
    ▼
helm lint
    │
    ▼
helm template
    │
    ▼
Validation result
```

The production manifest is not modified as part of validation.

---

## `prepare_readiness_remediation`

After validation succeeds, AgentOps can prepare the remediation locally.

It:

1. creates a dedicated Git branch;
2. applies the validated change;
3. creates a local commit; and
4. stops before any remote or production action.

Example:

```text
prepared: true
branch: agent/readiness-port-80
commit: <commit-sha>

pushed: false
pull_request_created: false
production_changed: false

next_action:
Human approval required before push/PR.
```

---

# Guardrails

AgentOps uses multiple layers of controls.

```text
┌─────────────────────────────┐
│ 1. Narrow MCP capabilities  │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 2. Constrained remediation  │
│    types                    │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 3. Input policy validation  │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 4. Helm validation          │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 5. Git-only remediation     │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 6. Human approval           │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 7. PR CI validation         │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 8. GitOps reconciliation    │
└─────────────────────────────┘
```

## Policy Enforcement

Guardrails are enforced by deterministic code rather than relying only on the LLM prompt.

For example, attempting to propose an impossible readiness port:

```text
70000
```

is rejected:

```text
valid: false

reason:
Policy violation: port must be between 1 and 65535.

production_changed: false
```

This is an important design property:

> **The model does not decide whether its own action is allowed.**

---

# CI Safety Gate

Local validation is not the final trust boundary.

Agent-generated changes are independently validated again through GitHub Actions when they reach the pull-request workflow.

```text
Agent
   │
   ▼
Local validation
   │
   ▼
Human-approved publication
   │
   ▼
Pull Request
   │
   ▼
GitHub Actions
   │
   ├── Policy validation
   ├── Helm lint
   └── Helm template
   │
   ▼
Human review / merge
```

This provides a second validation boundary outside the agent runtime.

The CI policy gate was also tested against an intentionally invalid readiness-port change and correctly rejected the change.

---

# Why GitOps?

AgentOps deliberately uses Git as the remediation boundary.

An alternative design would allow the AI agent to execute commands such as:

```text
kubectl patch
kubectl apply
helm upgrade
argocd app sync
```

directly against production.

AgentOps avoids that model.

Instead:

```text
AI
 │
 ▼
Git change
 │
 ▼
Review
 │
 ▼
CI
 │
 ▼
Merge
 │
 ▼
ArgoCD
 │
 ▼
Kubernetes
```

This provides:

- an auditable change history;
- reviewable diffs;
- CI enforcement;
- rollback through Git;
- separation between reasoning and deployment;
- a clear human approval boundary.

---

# Design Principles

## 1. Read broadly, write narrowly

An operations agent needs enough context to understand an incident.

AgentOps therefore allows evidence gathering across multiple systems while keeping mutation capabilities deliberately constrained.

```text
Broad observability
       +
Narrow remediation
```

---

## 2. Deterministic guardrails over prompt guardrails

A prompt such as:

```text
"Do not make dangerous production changes."
```

is useful guidance, but it is not a security boundary.

AgentOps places safety controls in deterministic code and CI.

The agent can request an operation.

The platform decides whether that operation is permitted.

---

## 3. GitOps as the control plane

AI-generated remediations become normal infrastructure changes:

```text
proposal
   ↓
validation
   ↓
commit
   ↓
review
   ↓
CI
   ↓
merge
   ↓
reconciliation
```

This keeps AI operations compatible with existing engineering workflows rather than creating a separate privileged deployment path.

---

## 4. Human approval for production impact

AgentOps intentionally separates:

```text
ability to diagnose
```

from:

```text
authority to deploy
```

The agent can perform useful operational work without being given unrestricted authority over production.

---

# Tech Stack

| Area | Technology |
|---|---|
| Cloud | AWS |
| Kubernetes | Amazon EKS |
| GitOps | ArgoCD |
| Observability | Prometheus |
| Packaging | Helm |
| Agent tooling | Model Context Protocol (MCP) |
| Agent client | Claude Code |
| AgentOps implementation | Python |
| CI | GitHub Actions |
| Version control | Git / GitHub |

---

# Repository Structure

```text
k8s-agentops/
└── agentops/
    ├── scripts/
    │   └── policy_check.py
    │
    ├── tools/
    │   ├── argocd.py
    │   ├── gitops.py
    │   ├── investigation.py
    │   ├── kubernetes.py
    │   ├── prometheus.py
    │   ├── remediation.py
    │   └── validation.py
    │
    ├── requirements.txt
    └── server.py
```
---
> **Note:** This repository focuses specifically on the AgentOps layer. For the complete underlying AWS/EKS infrastructure, GitOps platform, CI/CD, networking and observability setup, see **[ClusterCore](https://github.com/mazin1hn/eks)** 
---

# Running AgentOps Locally

## Prerequisites

The local environment requires:

- Python
- Kubernetes access
- `kubectl`
- Helm
- Git
- access to the target ArgoCD instance
- access to the target Prometheus instance
- an MCP-compatible client such as Claude Code

Clone the repository:

```bash
git clone <repository-url>
cd k8s-agentops
```

Create and activate the Python environment according to the project configuration.

The AgentOps MCP server is implemented in:

```text
agentops/server.py
```

The server can be inspected during development using an MCP-compatible development client.

---

# Claude Code Integration

AgentOps can be registered as a project-scoped MCP server for Claude Code.

Once configured, Claude Code can discover the AgentOps tools through MCP and use them during an investigation.

The resulting architecture is:

```text
Claude Code
     │
     │ MCP
     ▼
AgentOps
     │
     ├── ArgoCD
     ├── Kubernetes
     ├── Prometheus
     └── Git
```

The AI agent remains the reasoning layer.

AgentOps remains the constrained execution layer.

---

# Example Agent Prompt

An incident can be handed to the agent using natural language:

```text
Investigate why eks-app in namespace eks-app is unhealthy.

Do not make any direct infrastructure or production changes.

Use the AgentOps MCP tools to gather evidence, determine the root
cause, propose and validate a remediation, and prepare the remediation
in Git if it is safe to do so.

Stop before any push, pull request, merge, ArgoCD sync, or direct
Kubernetes mutation.

I must explicitly approve any action beyond preparing the local
remediation.
```

In the readiness-probe demo, the agent autonomously:

```text
Investigated
     ↓
Correlated evidence
     ↓
Identified root cause
     ↓
Proposed port 9999 → 80
     ↓
Validated the change
     ↓
Created local remediation branch
     ↓
Created local commit
     ↓
STOPPED
```

No production mutation was performed.

---

# Current Scope

AgentOps is currently a proof of concept focused on demonstrating the safety architecture around agent-driven Kubernetes remediation.

The current remediation path intentionally supports a narrow class of change: correcting an invalid readiness-probe port.

This is deliberate.

The goal is not to give an LLM a generic shell and call it an operations agent.

The goal is to demonstrate how increasingly capable remediation actions can be exposed through **explicit, testable and policy-controlled interfaces**.

Future remediation types could follow the same pattern:

```text
Observe
   ↓
Diagnose
   ↓
Propose constrained change
   ↓
Validate
   ↓
Prepare Git remediation
   ↓
Human approval
```

Potential extensions include:

- resource request/limit remediation;
- replica configuration;
- image/version rollback proposals;
- ingress configuration;
- deployment rollback recommendations;
- alert-driven investigation;
- multi-application incident correlation;
- richer Prometheus-based diagnosis.

---

# Key Takeaway

AgentOps is not designed to answer:

> **"How can I let an AI agent control my Kubernetes cluster?"**

It is designed around a different question:

> **"How much useful operational work can an AI agent perform without giving it unrestricted production authority?"**

The result is an agent that can investigate real infrastructure, correlate evidence, reason about failures and prepare validated remediations - while production changes remain reviewable, auditable and human-controlled.