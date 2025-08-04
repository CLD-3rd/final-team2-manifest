# ArgoCD App of Apps 패턴 - GitOps 환경 구축

## 📋 개요

이 프로젝트는 ArgoCD를 사용한 GitOps 환경을 구축하는 프로젝트입니다. App of Apps 패턴을 사용하여 멀티 환경(dev/prod)을 관리합니다.

## 🏗️ 아키텍처

```
manifest/
├── base/                    # 기본 설정
│   ├── argocd/             # ArgoCD 기본 설정
│   │   ├── namespace.yaml
│   │   └── install.yaml
│   ├── apps/               # 애플리케이션 설정
│   │   └── app-of-apps.yaml
│   └── kustomization.yaml
├── overlays/               # 환경별 설정
│   ├── dev/               # 개발 환경
│   │   ├── kustomization.yaml
│   │   └── patches/
│   │       ├── argocd-patch.yaml
│   │       └── app-of-apps-patch.yaml
│   └── prod/              # 운영 환경
│       ├── kustomization.yaml
│       └── patches/
│           ├── argocd-patch.yaml
│           └── app-of-apps-patch.yaml
└── README.md
```

## 🚀 설치 단계

### 1단계: 사전 요구사항 확인

```powershell
# AWS CLI 설치 확인
aws --version

# kubectl 설치 확인
kubectl version --client

# Helm 설치 확인
helm version
```

### 2단계: EKS 클러스터 연결

```powershell
# 클러스터 연결
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster

# 연결 확인
kubectl get nodes
```

### 3단계: ArgoCD 설치

#### 방법 1: 직접 설치
```powershell
# 개발 환경 설치
.\scripts\install-argocd.ps1 -Environment dev

# 운영 환경 설치
.\scripts\install-argocd.ps1 -Environment prod
```

#### 방법 2: SSM을 통한 원격 설치
```powershell
# 개발 환경 원격 설치
.\scripts\ssm-deploy-argocd.ps1 -Environment dev

# 운영 환경 원격 설치
.\scripts\ssm-deploy-argocd.ps1 -Environment prod
```

### 4단계: App of Apps 패턴 설정

```powershell
# 기본 App of Apps 애플리케이션 적용
kubectl apply -f manifest/base/apps/app-of-apps.yaml
```

## 🔧 환경별 설정

### 개발 환경 (dev)
- 네임스페이스: `argocd-dev`
- 도메인: `argocd-dev.example.com`
- 인증서: `letsencrypt-staging`
- 자동 동기화: 활성화

### 운영 환경 (prod)
- 네임스페이스: `argocd-prod`
- 도메인: `argocd.example.com`
- 인증서: `letsencrypt-prod`
- 자동 동기화: 활성화

## 📊 모니터링 및 접속

### ArgoCD UI 접속
- 개발 환경: https://argocd-dev.example.com
- 운영 환경: https://argocd.example.com

### 기본 로그인 정보
- 사용자: `admin`
- 비밀번호: `AdminPassword123`

### 상태 확인
```powershell
# ArgoCD Pod 상태 확인
kubectl get pods -n argocd-dev
kubectl get pods -n argocd-prod

# 애플리케이션 상태 확인
kubectl get applications -n argocd-dev
kubectl get applications -n argocd-prod
```

## 🔄 App of Apps 패턴 동작 원리

1. **루트 애플리케이션**: `app-of-apps`가 각 환경의 overlay를 관리
2. **환경별 관리**: dev/prod 환경별로 별도의 네임스페이스와 설정
3. **자동 동기화**: Git 저장소 변경 시 자동으로 클러스터에 반영
4. **헬스 체크**: 애플리케이션 상태 자동 모니터링

## 🛠️ 문제 해결

### 일반적인 문제들

#### 1. ArgoCD Pod가 시작되지 않는 경우
```powershell
# Pod 로그 확인
kubectl logs -n argocd-dev deployment/argocd-server

# 이벤트 확인
kubectl get events -n argocd-dev --sort-by='.lastTimestamp'
```

#### 2. 인증서 문제
```powershell
# cert-manager 상태 확인
kubectl get clusterissuer
kubectl get certificates -n argocd-dev
```

#### 3. 네트워크 연결 문제
```powershell
# Service 상태 확인
kubectl get svc -n argocd-dev
kubectl get ingress -n argocd-dev
```

## 📝 커스터마이징

### 새로운 애플리케이션 추가

1. `manifest/base/apps/` 디렉토리에 새 애플리케이션 YAML 생성
2. `manifest/base/kustomization.yaml`에 리소스 추가
3. 환경별 패치 파일 생성 (필요시)

### 환경별 설정 변경

1. `manifest/overlays/{env}/patches/` 디렉토리의 패치 파일 수정
2. `kubectl apply -k manifest/overlays/{env}/` 실행

## 🔒 보안 고려사항

1. **비밀번호 변경**: 기본 비밀번호를 강력한 비밀번호로 변경
2. **RBAC 설정**: 적절한 권한 설정
3. **네트워크 정책**: 필요한 포트만 열기
4. **로깅**: 감사 로그 활성화

## 📚 참고 자료

- [ArgoCD 공식 문서](https://argo-cd.readthedocs.io/)
- [App of Apps 패턴](https://argoproj.github.io/argo-cd/operator-manual/cluster-bootstrapping/)
- [Kustomize 문서](https://kustomize.io/)
- [Helm Charts](https://helm.sh/docs/)

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 