# ArgoCD App of Apps 패턴 - GitOps 환경 구축

## 📋 개요

이 프로젝트는 ArgoCD를 사용한 GitOps 환경을 구축하는 프로젝트입니다. **App of Apps 패턴**을 사용하여 **환경별(dev/prod) 분리 관리**를 수행합니다.

## 🏗️ 올바른 App of Apps 아키텍처

```
final-team2-manifest/
├── base/                           # 기본 설정 (환경 무관)
│   ├── argocd/                    # ArgoCD 설치만
│   │   ├── namespace.yaml
│   │   └── install.yaml
│   └── apps/
│       └── app-of-apps.yaml       # 🔑 루트 Application (환경별 overlay 참조)
└── overlays/                      # ✨ 환경별 분리 설정
    ├── dev/                       # 🧪 개발 환경
    │   ├── kustomization.yaml
    │   ├── patches/
    │   └── applications/          # Dev 환경 전용 애플리케이션들
    │       ├── nginx-ingress.yaml    # replica: 1, staging 인증서
    │       ├── cert-manager.yaml     # letsencrypt-staging
    │       └── backend-api.yaml      # api-dev.goteego.store
    └── prod/                      # 🚀 운영 환경
        ├── kustomization.yaml
        ├── patches/
        └── applications/          # Prod 환경 전용 애플리케이션들
            ├── nginx-ingress.yaml    # replica: 3, production 인증서
            ├── cert-manager.yaml     # letsencrypt-prod
            └── backend-api.yaml      # api.goteego.store
```

## 🔄 App of Apps 패턴 동작 원리

### **1단계: 루트 Application 배포**
```yaml
# base/apps/app-of-apps.yaml
spec:
  source:
    path: manifest/overlays/{{ENVIRONMENT}}  # 🎯 환경별 overlay 선택
```

### **2단계: 환경별 애플리케이션 배포**
- **Dev 선택시**: `overlays/dev/` → 개발 환경 설정
- **Prod 선택시**: `overlays/prod/` → 운영 환경 설정

## 🐳 환경별 Docker Hub 이미지 차이

### **Dev 환경:**
```yaml
containers:
- name: backend-api
  image: your-dockerhub-username/backend-api:dev-latest  # 🧪 개발 태그
  imagePullPolicy: Always        # 항상 최신 이미지
  replicas: 1                    # 적은 리소스
  resources:
    requests: {cpu: 100m, memory: 128Mi}
    limits: {cpu: 200m, memory: 256Mi}
```

### **Prod 환경:**
```yaml
containers:
- name: backend-api
  image: your-dockerhub-username/backend-api:latest      # 🚀 안정 태그
  imagePullPolicy: IfNotPresent  # 안정성 우선
  replicas: 3                    # 고가용성
  resources:
    requests: {cpu: 250m, memory: 256Mi}
    limits: {cpu: 500m, memory: 512Mi}
```

## 🌐 환경별 도메인 구조

| 환경 | Frontend | Backend API | ArgoCD UI | 인증서 |
|------|----------|------------|-----------|--------|
| **Dev** | `goteego.store` | `api-dev.goteego.store` | `argocd-dev.goteego.store` | `letsencrypt-staging` |
| **Prod** | `goteego.store` | `api.goteego.store` | `argocd.goteego.store` | `letsencrypt-prod` |

## 🚀 배포 방법

### **Dev 환경 배포:**
```powershell
# 1. ArgoCD 설치
kubectl apply -f base/argocd/install.yaml

# 2. Dev 환경 App of Apps 배포
kubectl apply -k overlays/dev/

# 3. 상태 확인
kubectl get applications -n argocd-dev
```

### **Prod 환경 배포:**
```powershell
# Prod 환경 App of Apps 배포
kubectl apply -k overlays/prod/

# 상태 확인
kubectl get applications -n argocd-prod
```

## 🔧 환경별 차이점 요약

| 구분 | Dev 환경 | Prod 환경 |
|------|----------|-----------|
| **리소스** | 낮음 (1 replica) | 높음 (3 replicas) |
| **인증서** | Staging (테스트용) | Production (실제용) |
| **로그 레벨** | Debug | Info |
| **이미지 정책** | Always (최신) | IfNotPresent (안정) |
| **도메인** | `api-dev.goteego.store` | `api.goteego.store` |
| **네임스페이스** | `*-dev` | `*-prod` |

## ✅ App of Apps 패턴의 장점

1. **환경 분리**: Dev/Prod 완전 독립 관리
2. **설정 재사용**: Base 설정을 환경별로 오버라이드
3. **GitOps 원칙**: Git이 단일 진실 공급원(SSOT)
4. **자동 동기화**: Git 변경시 자동 배포
5. **롤백 지원**: Git 기반 버전 관리

## 🛠️ 문제 해결

### 환경별 애플리케이션 상태 확인
```powershell
# Dev 환경
kubectl get applications -n argocd-dev
kubectl get pods -n backend-dev

# Prod 환경  
kubectl get applications -n argocd-prod
kubectl get pods -n backend-prod
```

### Docker Hub 이미지 업데이트
```yaml
# Dev: 개발 이미지 업데이트
image: your-dockerhub-username/backend-api:dev-v1.2.0

# Prod: 안정 버전 승격
image: your-dockerhub-username/backend-api:v1.2.0
```

## 📝 새로운 애플리케이션 추가

1. **환경별 애플리케이션 파일 생성**:
   - `overlays/dev/applications/new-app.yaml`
   - `overlays/prod/applications/new-app.yaml`

2. **Kustomization에 추가**:
   ```yaml
   # overlays/{env}/kustomization.yaml
   resources:
     - applications/new-app.yaml
   ```

3. **환경별 차이점 설정**:
   - Dev: 적은 리소스, staging 인증서
   - Prod: 높은 리소스, production 인증서

**🎯 이제 App of Apps 패턴이 올바르게 환경별로 분리되었습니다!** 