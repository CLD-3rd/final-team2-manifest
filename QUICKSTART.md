# 🚀 ArgoCD App of Apps - 빠른 시작 가이드

## ⚡ 5분 만에 시작하기

### 1. 사전 요구사항 확인
```powershell
# 필수 도구 확인
aws --version
kubectl version --client
helm version
```

### 2. EKS 클러스터 연결
```powershell
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster
kubectl get nodes
```

### 3. ArgoCD 설치 (한 줄 명령어)
```powershell
# 개발 환경
.\scripts\install-argocd.ps1 -Environment dev

# 운영 환경
.\scripts\install-argocd.ps1 -Environment prod
```

### 4. 접속 확인
```powershell
# 포트 포워딩
kubectl port-forward svc/argocd-server 8080:443 -n argocd-dev

# 브라우저에서 https://localhost:8080 접속
# 사용자: admin
# 비밀번호: AdminPassword123
```

## 📋 체크리스트

- [ ] AWS CLI 설치 및 설정
- [ ] kubectl 설치
- [ ] Helm 설치
- [ ] EKS 클러스터 연결
- [ ] ArgoCD 설치
- [ ] App of Apps 패턴 설정
- [ ] 환경별 설정 적용
- [ ] 접속 테스트

## 🔧 문제 해결

### 자주 발생하는 문제

#### 1. kubectl 연결 실패
```powershell
# AWS 자격 증명 확인
aws sts get-caller-identity

# 클러스터 재연결
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster
```

#### 2. ArgoCD Pod 시작 실패
```powershell
# 리소스 확인
kubectl get pods -n argocd-dev
kubectl describe pod -n argocd-dev deployment/argocd-server
```

#### 3. 인증서 문제
```powershell
# cert-manager 설치
helm install cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true
```

## 📞 지원

- 📖 [상세 매뉴얼](MANUAL.md)
- 📚 [전체 문서](README.md)
- 🐛 [문제 해결](MANUAL.md#문제-해결-가이드)

## 🎯 다음 단계

1. [새로운 애플리케이션 추가](README.md#새로운-애플리케이션-추가)
2. [환경별 설정 커스터마이징](README.md#환경별-설정-변경)
3. [모니터링 설정](MANUAL.md#6단계-모니터링-설정) 