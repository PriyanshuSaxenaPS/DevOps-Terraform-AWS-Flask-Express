#!/usr/bin/env bash
set -euo pipefail
echo "Part 1: curl -i http://EC2_PUBLIC_IP:3000 and curl -i http://EC2_PUBLIC_IP:5000/api/hello"
echo "Part 2: curl -i http://FRONTEND_PUBLIC_IP:3000 and curl -i http://BACKEND_PUBLIC_IP:5000/api/hello"
echo "Part 3: curl -i http://ALB_DNS/ and curl -i http://ALB_DNS/api/hello"
