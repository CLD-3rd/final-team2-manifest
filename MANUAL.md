# ArgoCD App of Apps 패턴 - 단계별 매뉴얼 (Terraform 이후)

## 📋 목차

1. [사전 준비](#사전-준비)
2. [1단계: 클러스터 연결](#1단계-클러스터-연결)
3. [2단계: ArgoCD UI 접속(HTTP)](#2단계-argocd-ui-접속http)
4. [3단계: App of Apps 구성](#3단계-app-of-apps-구성)
5. [4단계: 환경별 오버레이 적용](#4단계-환경별-오버레이-적용)
6. [5단계: 검증](#5단계-검증)
7. [부록: cert-manager 관련(현재 시나리오에선 미사용)](#부록-cert-manager-관련현재-시나리오에선-미사용)

---

## 사전 준비

- AWS CLI, kubectl이 설치되어 있어야 합니다.
- Terraform으로 EKS와 ArgoCD가 이미 설치되어 있다고 가정합니다.

---

## 1단계: 클러스터 연결
```powershell
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster
kubectl get nodes
```

---

## 2단계: ArgoCD UI 접속(HTTP)
```powershell
# 포트 포워딩 (HTTP)
kubectl port-forward svc/argocd-server 8080:80 -n argocd
# 브라우저에서 http://localhost:8080 접속
```

초기 관리자 계정: `admin`

---

## 3단계: App of Apps 구성
```powershell
@"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/CLD-3rd/final-team2-manifest.git
    targetRevision: dev
    path: overlays/dev  # dev 또는 prod로 선택
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
"@ | kubectl apply -f -
```
``` bash
kubectl apply -f - <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/CLD-3rd/final-team2-manifest.git
    targetRevision: dev
    path: overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF


---

## 4단계: 환경별 오버레이 적용
- 기본 구조는 `base` + `overlays/{env}` 입니다.
- 환경별 패치 파일(`overlays/{env}/patches/app-of-apps-patch.yaml`)은 유지됩니다.

배포 상태 확인:
```powershell
kubectl get all -n backend-dev
# 또는
kubectl get all -n backend-prod
```

---

## 5단계: 검증
- ArgoCD UI에서 `app-of-apps`가 Healthy/Synced 인지 확인
- Ingress는 HTTP(80)로 동작합니다. TLS/인증서 설정은 없습니다.

---

## 부록: cert-manager 관련(현재 시나리오에선 미사용)
- 본 매뉴얼 시나리오에서는 cert-manager를 사용하지 않습니다.
- 추후 TLS(HTTPS)를 적용하려면 다음을 고려하세요:
  - cert-manager 설치 및 ClusterIssuer 구성
  - Ingress의 `spec.tls` 블록과 관련 어노테이션 추가
  - ALB 리스너 443 구성 