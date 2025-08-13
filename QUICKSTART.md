# 🚀 ArgoCD App of Apps - 빠른 시작 가이드

## ⚡ 5분 만에 시작하기 (Terraform 이후)

### 1. EKS 클러스터 연결
```powershell
aws eks update-kubeconfig --region ap-northeast-2 --name goteego-team-cluster
kubectl get nodes
```

### 2. ArgoCD 접속 (HTTP)
```powershell
# 포트 포워딩 (HTTP, 80 → 8080)
kubectl port-forward svc/argocd-server 8080:80 -n argocd

# 브라우저에서 http://localhost:8080 접속
# 사용자: admin
# 비밀번호: <초기 암호 또는 설정된 비밀번호>
```

### 3. App-of-Apps 생성 (dev 또는 prod 선택)
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
    path: overlays/dev  # dev 또는 prod
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

### 4. 동기화 확인
- ArgoCD UI에서 `app-of-apps`가 Healthy/Synced 상태인지 확인
- 애플리케이션 리소스 확인:
```powershell
kubectl get all -n backend-dev
# 또는
kubectl get all -n backend-prod
```

## 📋 체크리스트
- [ ] EKS 클러스터 연결
- [ ] ArgoCD UI HTTP 접속 확인
- [ ] App-of-Apps 생성 및 동기화
- [ ] 환경별 애플리케이션 배포 확인

## 🔧 문제 해결
- GitHub Public 리포 접근은 HTTPS로 동작하며, ArgoCD UI의 HTTP 노출과 무관합니다.
- 네트워크 egress 제한이 있는 환경이라면 GitHub로의 443 아웃바운드 허용이 필요합니다.

## 📞 지원
- 📖 [상세 매뉴얼](MANUAL.md)
- 📚 [전체 문서](README.md) 