#!/bin/bash

# ==============================================================================
# Computational Research Platform - Migration & Setup Script
# ==============================================================================
# This script establishes the new directory structure and migrates existing
# folders based on standard naming conventions.
# ==============================================================================

set -e

echo "🏗️  Initializing Computational Research Platform structure..."

# --- Helper Function: Create Component ---
create_component() {
    local path=$1
    local title=$2
    local priority=$3
    local description=$4

    # Create directory if it doesn't exist
    if [ ! -d "$path" ]; then
        echo "   Creating: $path"
        mkdir -p "$path"
    else
        echo "   Exists: $path"
    fi

    # Create README if it doesn't exist
    if [ ! -f "$path/README.md" ]; then
        cat <<EOF > "$path/README.md"
# $title

**Priority:** $priority
**Description:** $description

## Overview
This component is part of the Computational Research Platform.

## Responsibilities
- [ ] Implementation of $description
EOF
    fi
}

# --- Helper Function: Smart Move ---
# Checks for a source directory and moves it if found
smart_move() {
    local dest=$1
    shift
    local sources=("$@") # Array of potential source names

    # Check if destination is empty (to avoid overwriting if run twice)
    if [ -n "$(ls -A $dest 2>/dev/null)" ] && [ "$dest" != "packages/taxonomy" ]; then
        # Exception for taxonomy as we might merge things there
        if [ "$dest/README.md" == "$(ls $dest)" ]; then
             : # It only contains the README we just made, safe to proceed
        else
             echo "   ⚠️  Destination $dest is not empty. Skipping move to prevent overwrite."
             return
        fi
    fi

    for src in "${sources[@]}"; do
        if [ -d "$src" ] && [ "$src" != "$dest" ]; then
            echo "   🚚 Moving '$src' -> '$dest'"
            # Move content of source to destination
            # We use rsync-like behavior: move contents, then remove source
            mv "$src"/* "$dest"/ 2>/dev/null || true
            mv "$src"/.* "$dest"/ 2>/dev/null || true
            rmdir "$src"
            return # Stop after finding the first match
        fi
    done
}

# ==============================================================================
# 1. CREATE DESTINATION STRUCTURE
# ==============================================================================

echo "📂 Creating Directory Skeleton..."

# Apps
create_component "apps/workbench" "The Co-Reasoning Canvas" "P5" "Primary interface for human-AI collaborative reasoning."
create_component "apps/voice-lab" "The Adaptive Voice Interface" "P4" "Voice-first interaction layer for experiments."
create_component "apps/alignment-dashboard" "Organization Voice Dashboard" "P6" "Visualization of alignment metrics."
create_component "apps/participant-ui" "Red Team Participant UI" "P3" "Frontend for Red Team agents."

# Packages
create_component "packages/taxonomy" "Shared Taxonomy" "Core" "Shared definitions, types, and ontology."
create_component "packages/governance" "Governance & Privacy" "Core" "PII Redaction and Anonymizers."
create_component "packages/evals" "Evaluations Library" "Core" "DSPy signatures and metrics."

# Docs
create_component "docs/decisions" "Architecture Decision Records" "Meta" "Log of all ADRs."

# Agents
create_component "agents/insight-council" "Insight Council" "P2" "Data-Grounded Synthetic Users."
create_component "agents/red-team" "Red Team Agent" "P3" "Multimodal Frustration Agent."
create_component "agents/partner" "The Co-Reasoning Agent" "P5" "Collaborative AI partner."

# Services
create_component "services/mcp-server" "MCP Server" "P1" "Contextual Triage Server (FastAPI/Cloud Run)."

# Notebooks
create_component "notebooks/experiments" "Experiments & Analysis" "P2" "Validation logic and Turing Test analysis."

# Data
create_component "data/ground-truth" "Ground Truth Datasets" "Core" "Gold Standard datasets."

# ==============================================================================
# 2. MIGRATION LOGIC (Smart Move)
# ==============================================================================
# This section attempts to find your old folders and move them to the new spots.
# It checks for common names (e.g., "frontend", "client") for each target.
# ==============================================================================

echo "----------------------------------------------------------------"
echo "📦 Starting Auto-Migration..."
echo "----------------------------------------------------------------"

# --- MIGRATING APPS ---

# 1. Workbench (The main UI)
# Looks for: 'frontend', 'client', 'ui', 'app'
smart_move "apps/workbench" "frontend" "client" "ui" "webapp"

# 2. Voice Lab
# Looks for: 'voice', 'audio', 'voice-ui'
smart_move "apps/voice-lab" "voice" "audio" "voice-frontend"

# 3. Alignment Dashboard
# Looks for: 'dashboard', 'admin', 'metrics'
smart_move "apps/alignment-dashboard" "dashboard" "admin" "analytics"

# 4. Participant UI
# Looks for: 'participant', 'survey', 'red-team-ui'
smart_move "apps/participant-ui" "participant" "survey-app" "external-ui"


# --- MIGRATING SERVICES ---

# 5. MCP Server (The main backend)
# Looks for: 'backend', 'server', 'api', 'service'
smart_move "services/mcp-server" "backend" "server" "api" "fastapi"


# --- MIGRATING PACKAGES ---

# 6. Taxonomy / Shared
# Looks for: 'shared', 'common', 'types', 'lib', 'utils'
smart_move "packages/taxonomy" "shared" "common" "lib" "utils" "types"

# 7. Governance
# Looks for: 'privacy', 'security', 'governance'
smart_move "packages/governance" "privacy" "security" "pii"

# 8. Evals
# Looks for: 'evals', 'evaluation', 'metrics'
smart_move "packages/evals" "evals" "evaluation" "benchmarks"


# --- MIGRATING AGENTS ---

# 9. Agents (General)
# If you have a general 'agents' folder, we might need to split it manually,
# but here we attempt to move specific agent folders if they exist at root.
smart_move "agents/red-team" "red-team" "adversarial"
smart_move "agents/insight-council" "insight-council" "personas" "synthetic-users"
smart_move "agents/partner" "partner" "copilot" "assistant"


# --- MIGRATING NOTEBOOKS ---

# 10. Notebooks
# Looks for: 'notebooks', 'research', 'experiments'
# Note: Since the target is 'notebooks/experiments', we handle this carefully
if [ -d "notebooks" ] && [ ! -d "notebooks/experiments" ]; then
    echo "   Refining 'notebooks' folder..."
    # If a root 'notebooks' exists, we move its contents into 'experiments'
    # unless it already matches the target structure
    mkdir -p "notebooks/experiments"
    mv notebooks/* notebooks/experiments/ 2>/dev/null || true
    # We don't remove the root notebooks folder since it's the parent
elif [ -d "research" ]; then
    smart_move "notebooks/experiments" "research"
fi

echo "----------------------------------------------------------------"
echo "✅ Migration Check Complete."
echo "   Please verify that files were moved to the correct locations."
echo "   If a folder was not moved, check if its name matched the defaults."
echo "----------------------------------------------------------------"
