swapoff -a

sed -i '/ swap / s/^/#/' /etc/fstab

modprobe br_netfilter

sh -c "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables"

sh -c "echo '1' > /proc/sys/net/ipv4/ip_forward"


export VERSION=1.28

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_9_Stream/devel:kubic:libcontainers:stable.repo

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/CentOS_9_Stream/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo

dnf install cri-o -y 

systemctl enable crio

systemctl start crio

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

dnf install -y kubelet-1.28.2 -y kubeadm-1.28.2  -y kubectl-1.28.2 --disableexcludes=kubernetes
systemctl enable kubelet
systemctl start kubelet
kubeadm init  --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
curl -Lo /tmp/tigera-operator.yaml https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml
kubectl create -f /tmp/tigera-operator.yaml
curl -Lo /tmp/custom-resources.yaml https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml
sed -i "s|192.168.0.0/16|10.244.0.0.16|" /tmp/custom-resources.yaml
kubectl create -f /tmp/custom-resources.yaml
kubectl get nodes
