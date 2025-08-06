# 🚀 final-team2-manifest

> **GitOps 기반 애플리케이션 배포 매니페스트**

## 📋 **개요**

이 리포지토리는 ArgoCD를 통한 GitOps 기반 애플리케이션 배포를 위한 Kubernetes 매니페스트 저장소입니다.
**Terraform에서 이미 인프라(EKS, ArgoCD, cert-manager)를 설치했으므로, 여기서는 애플리케이션만 관리합니다.**

## 🔧 **사용자가 설정해야 할 값들**

### **🚨 필수 설정 항목**

1. **Docker Hub 사용자명**
   - 파일: `overlays/dev/applications/backend-api.yaml`, `overlays/prod/applications/backend-api.yaml`
   - 설정: `cjsqudwns/goteego-server:latest` ✅ **완료**

2. **도메인명**
   - 파일: `overlays/dev/applications/backend-api.yaml`, `overlays/prod/applications/backend-api.yaml`
   - 설정: `api.goteego.store` ✅ **완료**

3. **데이터베이스 엔드포인트** ✅ **완료**
   - PostgreSQL Primary: `10.0.20.1` (AZ1)
   - PostgreSQL Secondary: `10.0.21.1` (AZ2)
   - MongoDB Primary: `10.0.30.1` (AZ1)
   - MongoDB Secondary: `10.0.31.1` (AZ2)
   - ElastiCache Redis Primary: `10.0.40.1` (AZ1)
   - ElastiCache Redis Secondary: `10.0.41.1` (AZ2)

4. **cert-manager ClusterIssuer**
   - Dev: `letsencrypt-staging` ✅ **완료**
   - Prod: `letsencrypt-prod` (권장) 또는 `letsencrypt-staging`

## 🏗️ **구조**

```
final-team2-manifest/
├── base/
│   └── apps/
│       └── app-of-apps.yaml          # App-of-Apps 패턴
└── overlays/
    ├── dev/
    │   ├── applications/
    │   │   └── backend-api.yaml      # Dev 환경 백엔드 API
    │   ├── patches/
    │   │   └── app-of-apps-patch.yaml
    │   └── kustomization.yaml
    └── prod/
        ├── applications/
        │   └── backend-api.yaml      # Prod 환경 백엔드 API
        ├── patches/
        │   └── app-of-apps-patch.yaml
        └── kustomization.yaml
```

## 🚀 **배포 방법**

### **1. App-of-Apps 생성 (GitOps 매뉴얼 참조)**

```powershell
# PowerShell에서 App-of-Apps 생성
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
    path: final-team2-manifest/overlays/dev  # dev 또는 prod
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

### **2. ArgoCD 웹 UI에서 확인**
- ArgoCD 웹 UI 접속
- Applications 메뉴에서 `app-of-apps` 확인
- 자동 동기화 확인

## 🔄 **환경별 차이점**

| 항목 | Dev | Prod |
|------|-----|------|
| **Replicas** | 1 | 3 |
| **Resources** | 128Mi/100m | 256Mi/250m |
| **Image Policy** | Always | IfNotPresent |
| **Docker Image** | `cjsqudwns/goteego-server:latest` | `cjsqudwns/goteego-server:latest` |
| **Log Level** | debug | info |
| **Domain** | `api.goteego.store` | `api.goteego.store` |
| **SSL** | letsencrypt-staging | letsencrypt-prod |
| **DB Name** | goteego_dev | goteego_prod |

## 🔧 **수정 완료 사항**

✅ **제거된 항목들**:
- ~~ArgoCD 설치 (인프라에서 이미 설치함)~~
- ~~cert-manager 설치 (인프라에서 이미 설치함)~~
- ~~nginx-ingress 설치 (AWS Load Balancer Controller 사용)~~

✅ **변경된 항목들**:
- **Ingress**: nginx → AWS Load Balancer Controller (ALB)
- **경로**: `manifest/overlays/` → `final-team2-manifest/overlays/`
- **네임스페이스**: `argocd-dev/prod` → `argocd` (통합)

## 📝 **다음 단계**

1. ✅ **Docker Hub 설정 완료**: `cjsqudwns/goteego-server:latest`
2. ✅ **도메인 설정 완료**: `api.goteego.store`
3. ✅ **DB 엔드포인트 설정 완료**: Private IP로 Multi-AZ 구성
4. 🔄 **Docker 이미지 빌드 및 푸시** (아직 필요시)
5. 🔄 **Git에 변경사항 커밋 & 푸시**
6. 🔄 **ArgoCD에서 자동 동기화 확인**

## 🎯 **즉시 실행 가능**

**이제 모든 필수 설정이 완료되어 바로 GitOps 워크플로우를 시작할 수 있습니다!**

## 🚨 **주의사항**

- **인프라 컴포넌트는 수정하지 마세요** (EKS, ArgoCD, cert-manager는 Terraform에서 관리)
- **실제 운영 전에 Dev 환경에서 충분히 테스트하세요**
- **Production 환경에서는 `letsencrypt-prod` 사용을 권장합니다**

---

**Happy GitOps! 🎉** 