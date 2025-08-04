# ArgoCD App of Apps 패턴 - 단계별 설치 매뉴얼

## 📋 목차

1. [사전 준비](#사전-준비)
2. [1단계: 기본 인프라 설정](#1단계-기본-인프라-설정)
3. [2단계: ArgoCD 설치](#2단계-argocd-설치)
4. [3단계: App of Apps 패턴 구성](#3단계-app-of-apps-패턴-구성)
5. [4단계: 환경별 설정](#4단계-환경별-설정)
6. [5단계: 검증 및 테스트](#5단계-검증-및-테스트)
7. [6단계: 모니터링 설정](#6단계-모니터링-설정)

---

## 사전 준비

### 필수 도구 설치

#### 1. AWS CLI 설치
```powershell
# Windows용 AWS CLI 설치
winget install Amazon.AWSCLI

# 또는 Chocolatey 사용
choco install awscli

# 설치 확인
aws --version
```

#### 2. kubectl 설치
```powershell
# kubectl 설치
winget install Kubernetes.kubectl

# 설치 확인
kubectl version --client
```

#### 3. Helm 설치
```powershell
# Helm 설치
winget install Helm.Helm

# 설치 확인
helm version
```

### AWS 자격 증명 설정
```powershell
# AWS 자격 증명 설정
aws configure

# 입력할 정보:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region name: ap-northeast-2
# Default output format: json
```

---

## 1단계: 기본 인프라 설정

### EKS 클러스터 연결
```powershell
# 클러스터 연결
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster

# 연결 확인
kubectl get nodes
```

### 필수 네임스페이스 생성
```powershell
# cert-manager 네임스페이스
kubectl create namespace cert-manager

# nginx-ingress 네임스페이스
kubectl create namespace nginx-ingress
```

### cert-manager 설치
```powershell
# Helm을 통한 cert-manager 설치
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true \
  --version v1.13.3

# 설치 확인
kubectl get pods -n cert-manager
```

### ClusterIssuer 생성
```powershell
# staging ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# production ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

---

## 2단계: ArgoCD 설치

### 방법 선택

#### 방법 A: 직접 설치 (권장)
```powershell
# 개발 환경 설치
.\scripts\install-argocd.ps1 -Environment dev

# 운영 환경 설치
.\scripts\install-argocd.ps1 -Environment prod
```

#### 방법 B: SSM을 통한 원격 설치
```powershell
# 개발 환경 원격 설치
.\scripts\ssm-deploy-argocd.ps1 -Environment dev

# 운영 환경 원격 설치
.\scripts\ssm-deploy-argocd.ps1 -Environment prod
```

### 설치 확인
```powershell
# Pod 상태 확인
kubectl get pods -n argocd-dev
kubectl get pods -n argocd-prod

# Service 확인
kubectl get svc -n argocd-dev
kubectl get svc -n argocd-prod

# Ingress 확인
kubectl get ingress -n argocd-dev
kubectl get ingress -n argocd-prod
```

---

## 3단계: App of Apps 패턴 구성

### 기본 App of Apps 애플리케이션 적용
```powershell
# 개발 환경용 App of Apps
kubectl apply -f manifest/base/apps/app-of-apps.yaml
```

### Git 저장소 설정
```powershell
# Git 저장소 URL 업데이트 (실제 저장소 URL로 변경)
# manifest/base/apps/app-of-apps.yaml 파일에서
# repoURL: https://github.com/your-org/your-repo.git 부분을
# 실제 Git 저장소 URL로 변경
```

### 환경별 설정 적용
```powershell
# 개발 환경 설정 적용
kubectl apply -k manifest/overlays/dev/

# 운영 환경 설정 적용
kubectl apply -k manifest/overlays/prod/
```

---

## 4단계: 환경별 설정

### 개발 환경 (dev) 설정

#### 네임스페이스 확인
```powershell
kubectl get namespace argocd-dev
```

#### 설정 확인
```powershell
# ConfigMap 확인
kubectl get configmap -n argocd-dev

# 애플리케이션 확인
kubectl get applications -n argocd-dev
```

### 운영 환경 (prod) 설정

#### 네임스페이스 확인
```powershell
kubectl get namespace argocd-prod
```

#### 설정 확인
```powershell
# ConfigMap 확인
kubectl get configmap -n argocd-prod

# 애플리케이션 확인
kubectl get applications -n argocd-prod
```

---

## 5단계: 검증 및 테스트

### ArgoCD 서버 접속 테스트
```powershell
# 포트 포워딩으로 로컬 접속 테스트
kubectl port-forward svc/argocd-server 8080:443 -n argocd-dev

# 브라우저에서 https://localhost:8080 접속
# 사용자: admin
# 비밀번호: AdminPassword123
```

### 애플리케이션 동기화 테스트
```powershell
# 동기화 상태 확인
kubectl get applications -n argocd-dev -o wide

# 동기화 로그 확인
kubectl logs -n argocd-dev deployment/argocd-application-controller
```

### 인증서 발급 확인
```powershell
# 인증서 상태 확인
kubectl get certificates -n argocd-dev
kubectl get certificates -n argocd-prod

# ClusterIssuer 상태 확인
kubectl get clusterissuer
```

---

## 6단계: 모니터링 설정

### ArgoCD 알림 설정
```powershell
# 알림 템플릿 생성
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd-dev
data:
  service.slack: |
    token: $slack-token
  template.app-sync-succeeded: |
    message: |
      Application {{.app.metadata.name}} sync succeeded.
      Environment: {{.app.metadata.namespace}}
      Repository: {{.app.spec.source.repoURL}}
      Revision: {{.app.spec.source.targetRevision}}
  template.app-sync-failed: |
    message: |
      Application {{.app.metadata.name}} sync failed.
      Environment: {{.app.metadata.namespace}}
      Repository: {{.app.spec.source.repoURL}}
      Revision: {{.app.spec.source.targetRevision}}
      Error: {{.failure}}
  trigger.on-sync-succeeded: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-sync-succeeded]
  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]
EOF
```

### 로깅 설정
```powershell
# ArgoCD 로그 레벨 설정
kubectl patch deployment argocd-server -n argocd-dev --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--log-level=debug"}]'
```

---

## 🔧 문제 해결 가이드

### 일반적인 문제들

#### 1. ArgoCD Pod가 시작되지 않는 경우
```powershell
# Pod 상태 확인
kubectl get pods -n argocd-dev

# Pod 로그 확인
kubectl logs -n argocd-dev deployment/argocd-server

# 이벤트 확인
kubectl get events -n argocd-dev --sort-by='.lastTimestamp'

# 리소스 사용량 확인
kubectl top pods -n argocd-dev
```

#### 2. 인증서 발급 실패
```powershell
# cert-manager Pod 상태 확인
kubectl get pods -n cert-manager

# ClusterIssuer 상태 확인
kubectl describe clusterissuer letsencrypt-staging
kubectl describe clusterissuer letsencrypt-prod

# 인증서 요청 상태 확인
kubectl get certificaterequests -n argocd-dev
```

#### 3. Git 저장소 연결 실패
```powershell
# ArgoCD 서버 로그 확인
kubectl logs -n argocd-dev deployment/argocd-server

# 네트워크 연결 테스트
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup github.com
```

#### 4. 동기화 실패
```powershell
# 애플리케이션 상태 확인
kubectl get applications -n argocd-dev -o yaml

# 동기화 로그 확인
kubectl logs -n argocd-dev deployment/argocd-application-controller

# 수동 동기화 실행
kubectl patch application app-of-apps -n argocd-dev --type='merge' -p='{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

---

## 📊 모니터링 명령어

### 상태 확인 명령어
```powershell
# 전체 상태 확인
kubectl get all -n argocd-dev
kubectl get all -n argocd-prod

# 애플리케이션 상태 확인
kubectl get applications -n argocd-dev -o wide
kubectl get applications -n argocd-prod -o wide

# 리소스 사용량 확인
kubectl top pods -n argocd-dev
kubectl top pods -n argocd-prod

# 로그 확인
kubectl logs -n argocd-dev deployment/argocd-server --tail=100 -f
kubectl logs -n argocd-prod deployment/argocd-server --tail=100 -f
```

### 백업 및 복구
```powershell
# 설정 백업
kubectl get applications -n argocd-dev -o yaml > argocd-dev-backup.yaml
kubectl get applications -n argocd-prod -o yaml > argocd-prod-backup.yaml

# 설정 복구
kubectl apply -f argocd-dev-backup.yaml
kubectl apply -f argocd-prod-backup.yaml
```

---

## 🎯 다음 단계

1. **새로운 애플리케이션 추가**: `manifest/base/apps/` 디렉토리에 새 애플리케이션 정의
2. **환경별 설정 커스터마이징**: `manifest/overlays/{env}/patches/` 디렉토리에서 환경별 설정 조정
3. **모니터링 강화**: Prometheus, Grafana 연동
4. **보안 강화**: RBAC, 네트워크 정책 설정
5. **CI/CD 파이프라인 구축**: GitHub Actions 또는 Jenkins 연동

---

## 📞 지원

문제가 발생하거나 추가 도움이 필요한 경우:
1. 이 매뉴얼의 문제 해결 섹션 확인
2. ArgoCD 공식 문서 참조
3. 팀 내 기술 지원팀에 문의 