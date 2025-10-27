# CI/CD Pipeline với GitHub Actions và ArgoCD

## Tổng quan
Đây là hệ thống CI/CD hoàn chỉnh sử dụng:
- **GitHub Actions**: Automated build, test và push Docker images
- **ArgoCD**: GitOps tool để tự động deploy ứng dụng lên Kubernetes
- **GitHub Container Registry**: Lưu trữ Docker images
- **Kubernetes**: Container orchestration platform

## Workflow CI/CD

### 1. Developer push code
```
git add .
git commit -m "New feature"
git push origin main
```

### 2. GitHub Actions tự động:
- ✅ Chạy tests
- ✅ Build Spring Boot application
- ✅ Build và push Docker image lên GHCR
- ✅ Update image tag trong k8s-manifests/deployment.yaml
- ✅ Commit thay đổi về repository

### 3. ArgoCD tự động:
- ✅ Phát hiện thay đổi trong Git repository
- ✅ Deploy version mới lên Kubernetes
- ✅ Rolling update với zero downtime
- ✅ Monitoring và health checks

## Cấu hình

### GitHub Actions Workflow
File: `.github/workflows/ci-cd.yml`
- Trigger: Push to main/develop branch
- Steps: Test → Build → Push Docker → Update K8s manifests
- Registry: GitHub Container Registry (ghcr.io)

### Kubernetes Manifests
Thư mục: `k8s-manifests/`
- `namespace.yaml`: Tạo namespace riêng
- `mysql-secret.yaml`: Database credentials
- `mysql.yaml`: MySQL deployment & service
- `deployment.yaml`: Spring Boot app deployment
- Health checks và resource limits

### ArgoCD Application
File: `argocd-application.yaml`
- Source: Git repository
- Destination: Kubernetes cluster
- Sync Policy: Automated with self-heal

## Truy cập Services

### ArgoCD UI
```
URL: http://localhost:30081
Username: admin
Password: qKYvKAuhgzvUOSvz
```

### Spring Boot Application
```
URL: http://localhost:30080
Health Check: http://localhost:30080/actuator/health
```

## Commands hữu ích

### Kiểm tra ArgoCD Applications
```bash
kubectl get applications -n argocd
kubectl describe application securing-web-app -n argocd
```

### Xem logs ArgoCD
```bash
kubectl logs -f deployment/argocd-server -n argocd
```

### Xem logs ứng dụng
```bash
kubectl logs -f deployment/securing-web-deployment -n securing-web-app
```

### Sync manual (nếu cần)
```bash
argocd app sync securing-web-app
```

## Troubleshooting

### 1. GitHub Actions fails
- Kiểm tra permissions trong repository settings
- Verify Docker registry credentials
- Check syntax trong workflow file

### 2. ArgoCD không sync
- Kiểm tra Git repository URL
- Verify service account permissions
- Check network connectivity

### 3. Application không healthy
- Xem logs: `kubectl logs -f deployment/securing-web-deployment -n securing-web-app`
- Check health endpoint: `/actuator/health`
- Verify database connection

## Security Notes

### Secrets Management
- Database passwords stored in Kubernetes Secrets
- GitHub Container Registry uses GITHUB_TOKEN
- ArgoCD credentials auto-generated

### Network Security
- Services exposed via NodePort (dev environment)
- For production: Use LoadBalancer hoặc Ingress
- Network policies configured

## Monitoring

### ArgoCD Dashboard
- Application status và health
- Sync history và rollback options
- Resource visualization

### Kubernetes Native
```bash
kubectl get pods -n securing-web-app
kubectl top pods -n securing-web-app
kubectl describe pod <pod-name> -n securing-web-app
```

## Rollback Strategy

### Via ArgoCD UI
1. Vào ArgoCD dashboard
2. Chọn application "securing-web-app"
3. Click "History and Rollback"
4. Chọn version muốn rollback

### Via kubectl
```bash
kubectl rollout undo deployment/securing-web-deployment -n securing-web-app
kubectl rollout history deployment/securing-web-deployment -n securing-web-app
```