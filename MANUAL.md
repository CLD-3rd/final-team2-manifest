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

## 2단계: ArgoCD UI 접속(HTTPS)
https://argocd.goteego.store
초기 관리자 계정: `admin`
비밀번호 :
---

## 3단계: manifest ingress ACM arn 수정
    1. Terraform apply 완료 후 ACM ARN 확인:
       terraform output acm_certificate_arn_ap_northeast_2
    
    2. Backend ingress 매니페스트 수정:
       final-team2-manifest/overlays/dev/applications/backend-api.yaml
       
       annotations 섹션에서:
       alb.ingress.kubernetes.io/certificate-arn:
       "${AP_NORTHEAST_2_ACM_ARN}"
       ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
       alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:ap-northeast-2:ACCOUNT:certificate/CERT-ID"
    
    3. ArgoCD로 배포:
       kubectl apply -f base/apps/app-of-apps.yaml
       
    4. Ingress 상태 확인:
       kubectl get ingress -n backend-dev
       kubectl describe ingress backend-api-ingress-dev -n backend-dev
    
    5. DNS 확인 (ExternalDNS가 자동 생성):
       nslookup dev.api.goteego.store
    
    ========================================
    ARGOCD TLS 설정 (자동 적용됨)
    ========================================
    
    ArgoCD는 Terraform에서 자동으로 TLS 설정됨:
    - HTTPS 443 리스너
    - ACM 인증서 연결
    - HTTP→HTTPS 리다이렉트
    
    접속 확인:
    https://argocd.goteego.store
    
    ========================================
    EOT
}


## 4단계: 검증
- ArgoCD UI에서 `app-of-apps`가 Healthy/Synced 인지 확인
- Ingress는 HTTPS(443)으로 동작합니다. TLS/인증서 설정은 ACM으로 했습니다.

---