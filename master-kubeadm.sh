#!/bin/bash 
echo "Step 1: Login with root user and Install Docker ( in Master & Worker Node Both)"
sudo apt-get update -y
sudo apt-get install \
ca-certificates \
curl \
gnupg -y

echo "Add Docker's official GPG key:"
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Add the repository to Apt sources:"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

echo "To install the latest version, run:"
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo "Step 2: Create a file with the name containerd.conf using the command:"
# create the file with root privileges using the vim editor
sudo vim /etc/modules-load.d/containerd.conf <<EOF
i
overlay
br_netfilter
Esc
:wq
EOF

echo "Step 3: Save the file and run the following commands:"
modprobe overlay
modprobe br_netfilter

echo "Step 4: Create a file with the name kubernetes.conf in /etc/sysctl.d folder:"
# create the file with root privileges using the vim editor
sudo vim /etc/sysctl.d/kubernetes.conf <<EOF
i
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
Esc
:wq
EOF

echo "Step 5: Run the commands to verify the changes:"
sudo sysctl --system
sudo sysctl -p

echo "Step 6: Remove the config.toml file from /etc/containerd/ Folder and run reload your system daemon:"
rm -f /etc/containerd/config.toml
systemctl daemon-reload

echo "Step 7: Add Kubernetes Repository:"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg -y
sudo mkdir -p -m 755 /etc/apt/keyrings
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

echo "Step 8: Disable Swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab  # This ensures swap remains off after a reboot
export KUBE_VERSION=1.31.2

echo "Step 9: Install Kubernetes:"
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet



echo "Step 11: Now it's time to initialize our Cluster!((Only on master node))"
echo "(Only on master node)"
#1.31.2
sudo kubeadm init --kubernetes-version=${KUBE_VERSION}
echo "(To regenrate the tokens)"
sudo kubeadm token create --print-join-command

echo "Step 12:(Only on master node)"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "Step 14: Now deploy a pod network to the cluster"
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml --validate=false
