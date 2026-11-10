# Cloud Native Deployment on AWS EKS with Terraform

Projet portfolio : déploiement d'une API FastAPI conteneurisée sur Amazon EKS, infrastructure AWS déclarative avec Terraform et livraison continue via GitHub Actions.

## Architecture

- **Terraform** : VPC multi-AZ, subnets publics/privés, cluster EKS et managed node group.
- **Application** : API FastAPI avec endpoint de santé et endpoint de version.
- **Kubernetes** : Deployment, Service et probes de disponibilité.
- **CI/CD** : tests Python, build Docker, push ECR puis déploiement sur EKS via GitHub Actions et OIDC (sans clé AWS longue durée).

> Coûts : EKS, NAT Gateway, EC2 et ECR peuvent générer des frais AWS. Détruire l'infrastructure après les tests (`terraform destroy`). Ce dépôt est un exemple pédagogique, pas une configuration de production certifiée.

## Prérequis

- AWS account et droits IAM adaptés
- Terraform >= 1.6, AWS CLI v2, kubectl, Docker
- Python 3.12 et Git
- Un dépôt GitHub

## 1. Déployer l'infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Modifier project_name, region et environment si nécessaire
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Récupérer les sorties et configurer kubectl :

```bash
aws eks update-kubeconfig --region eu-west-3 --name $(terraform output -raw cluster_name)
kubectl get nodes
```

## 2. Construire et tester l'application en local

```bash
cd ../app
python -m venv .venv
source .venv/bin/activate  # Windows : .venv\Scripts\activate
pip install -r requirements.txt
pytest -q
uvicorn main:app --reload
```

API : `http://127.0.0.1:8000/health` et `http://127.0.0.1:8000/version`.

## 3. Configurer GitHub Actions

Créer un repository ECR nommé `devops-demo` (ou adapter `ECR_REPOSITORY` dans le workflow). Ajouter les variables GitHub :

- `AWS_REGION` : région de l'infrastructure, par exemple `eu-west-3`
- `EKS_CLUSTER_NAME` : valeur de `terraform output -raw cluster_name`
- `ECR_REPOSITORY` : `devops-demo` (nom du dépôt ECR créé par Terraform)

Configurer le rôle IAM GitHub OIDC avec les permissions minimales nécessaires. Des exemples de trust policy et de permissions sont fournis dans `docs/` : remplacer les placeholders `<AWS_ACCOUNT_ID>`, `<AWS_REGION>`, `<GITHUB_OWNER>` et `<GITHUB_REPOSITORY>`, puis créer le rôle dans IAM. Ajouter son ARN dans le secret `AWS_ROLE_ARN`.

Autoriser ensuite ce rôle à accéder au cluster EKS (l'identité qui exécute Terraform doit avoir les droits nécessaires) :

```bash
aws eks create-access-entry --cluster-name <CLUSTER_NAME> --principal-arn <GITHUB_ACTIONS_ROLE_ARN> --type STANDARD
aws eks associate-access-policy --cluster-name <CLUSTER_NAME> --principal-arn <GITHUB_ACTIONS_ROLE_ARN> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy \
  --access-scope type=namespace,namespaces=default
```

Le rôle est ainsi limité à l'édition des ressources dans le namespace `default` pour ce scénario de démonstration.

Le workflow `.github/workflows/deploy.yml` lance les tests, construit/pousse l'image, puis applique les manifests Kubernetes. Le workflow suppose que le cluster et le repository ECR existent déjà. Le dépôt ECR est créé par Terraform ; renseigner `terraform output -raw ecr_repository_url` pour vérifier son URL. Le nom à mettre dans `ECR_REPOSITORY` est `devops-demo`.

## 4. Déploiement manuel (facultatif)

```bash
aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com
docker build -t devops-demo:local ./app
# Remplacer l'image dans k8s/deployment.yaml avant kubectl apply
kubectl apply -f k8s/
kubectl rollout status deployment/devops-api
kubectl get svc devops-api
```

Le Service est de type `LoadBalancer` : AWS provisionne un load balancer et cela peut générer des frais.

## Structure

```text
app/                 API FastAPI, tests et Dockerfile
terraform/           VPC + EKS déclarés en Terraform
k8s/                 manifests Kubernetes
.github/workflows/   pipeline GitHub Actions
```

## Améliorations possibles

- Ajouter HPA, PodDisruptionBudget, NetworkPolicies et secrets via AWS Secrets Manager.
- Ajouter Helm, Argo CD et un environnement de staging.
- Ajouter observabilité avec Prometheus/Grafana et logs centralisés.
- Mettre en place un backend Terraform distant chiffré avec verrouillage d'état.

## Nettoyage

Supprimer d'abord les ressources Kubernetes de type LoadBalancer, puis l'infrastructure :

```bash
kubectl delete -f ../k8s/ || true
cd terraform && terraform destroy
```
