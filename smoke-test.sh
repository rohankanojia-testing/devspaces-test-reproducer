#!/bin/bash

set -euo pipefail

# 🔧 CONFIGURATION
NAMESPACE="rokumar-dev"              # Change to your namespace
DW_NAME="failing-poststart-ws"
PVC_NAME="claim-devworkspace"
LOG_READER_NAME="log-reader"

echo "🔧 Applying DevWorkspace with failing postStart..."

cat <<EOF | kubectl apply -n "$NAMESPACE" -f -
apiVersion: workspace.devfile.io/v1alpha2
kind: DevWorkspace
metadata:
  name: ${DW_NAME}
  annotations:
    controller.devfile.io/debug-start: "true"
spec:
  started: true
  template:
    components:
      - name: tools
        container:
          image: alpine:latest
          volumeMounts:
            - name: logs
              path: /workspace/logs
          command: ["/bin/sh"]
          args: ["-c", "sleep infinity"]
      - name: logs
        volume: {}

    commands:
      - id: failing-command
        exec:
          commandLine: |
            cat << 'EOF' > /tmp/dummy-script.sh
            #!/bin/sh
            echo "Dummy script started"
            echo "This is stdout"
            echo "This is stderr" >&2
            exit 1
            EOF
            chmod +x /tmp/dummy-script.sh
            trap 'echo "[postStart] ❌ fail.sh failed at $(date)" >&2; sleep 3600' ERR; /tmp/dummy-script.sh
          component: tools

    events:
      postStart:
        - failing-command
EOF

echo "⏳ Waiting for DevWorkspace to start and fail..."
sleep 10

