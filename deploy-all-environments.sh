#!/bin/bash

# Dev와 Prod 환경 모두 배포하는 스크립트
echo "🚀 Dev와 Prod 환경 배포를 시작합니다..."

# 1. 네임스페이스 생성
echo "📁 네임스페이스 생성 중..."
kubectl create namespace argocd-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd-prod --dry-run=client -o yaml | kubectl apply -f -

# 2. Dev 환경 배포
echo "🔧 Dev 환경 배포 중..."
kubectl apply -f overlays/dev/patches/app-of-apps-patch.yaml

# 3. Prod 환경 배포
echo "🏭 Prod 환경 배포 중..."
kubectl apply -f overlays/prod/patches/app-of-apps-patch.yaml

# 4. 배포 상태 확인
echo "✅ 배포 완료! 상태 확인 중..."
echo ""
echo "📊 ArgoCD 애플리케이션 상태:"
kubectl get applications -n argocd-dev
kubectl get applications -n argocd-prod

echo ""
echo "🔍 Dev 환경 리소스:"
kubectl get all -n backend-dev

echo ""
echo "🔍 Prod 환경 리소스:"
kubectl get all -n backend-prod

echo ""
echo "🎉 배포가 완료되었습니다!"
echo "📝 다음 명령어로 상태를 확인할 수 있습니다:"
echo "   - Dev 환경: kubectl get applications -n argocd-dev"
echo "   - Prod 환경: kubectl get applications -n argocd-prod"
echo "   - Dev 파드: kubectl get pods -n backend-dev"
echo "   - Prod 파드: kubectl get pods -n backend-prod" 