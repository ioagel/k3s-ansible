# Automated build of HA k3s Cluster with ansible

This is based on the excellent work from [TechnoTim](https://github.com/techno-tim/k3s-ansible) whose repo I forked and combined it with code from another great repo by [ricsanfre](https://github.com/ricsanfre/pi-cluster). Finally, I put my own touches.

I removed support for Raspberry Pi, until I have at least one to test with.


## k3s Ansible Playbook

Build a Kubernetes cluster using Ansible with k3s. The goal is easily install a HA Kubernetes cluster on machines running:

- [X] Ubuntu
- [X] Debian
- [X] RedHat family (selinux disabled by default)

on processor architecture:

- [X] x64
- [X] arm64

### Features
- [x] [kube-vip](https://kube-vip.io/) provides a single virtual ip to access the control plane nodes
- [x] [metallb](https://metallb.universe.tf/) is the cluster Load Balancer
- [x] [cert-manager](https://github.com/cert-manager/cert-manager) for cluster certificate management
- [ ] [linkerd](https://github.com/linkerd/linkerd2) for the service mesh
- [ ] [traefik](https://github.com/traefik/traefik) for Ingress
- [ ] [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) for metrics, monitoring, alerting
- [ ] [grafana loki](https://github.com/grafana/loki) for logging

The file [all.yml](inventory/sample/group_vars/all.yml) in `inventory/sample/group_vars` is where you can customize a lot of the defaults, which is required for your own environment.

## System requirements

- Deployment environment must have Ansible 2.4.0+.  If you need a quick primer on Ansible [you can check out my docs and setting up Ansible](https://docs.technotim.live/posts/ansible-automation/).

- [`netaddr` package](https://pypi.org/project/netaddr/) must be available to Ansible. If you have installed Ansible via apt, this is already taken care of. If you have installed Ansible via `pip`, make sure to install `netaddr` into the respective virtual environment.

- `server` and `agent` nodes should have passwordless SSH access, if not you can supply arguments to provide credentials `--ask-pass --ask-become-pass` to each command.

- You will also need to install collections that this playbook uses by running `ansible-galaxy install -r ./collections/requirements.yml`

## Getting Started

### Preparation

First create a new directory based on the `sample` directory within the `inventory` directory:

```bash
cp -R inventory/sample inventory/my-cluster
```

Second, edit `inventory/my-cluster/hosts.ini` to match the system information gathered above

For example:

```ini
[master]
192.168.30.38
192.168.30.39
192.168.30.40

[node]
192.168.30.41
192.168.30.42

[k3s_cluster:children]
master
node
```

If multiple hosts are in the master group, the playbook will automatically set up k3s in [HA mode with etcd](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/).

This requires at least k3s version `1.19.1` however the version is configurable by using the `k3s_version` variable.

If needed, you can also edit `inventory/my-cluster/group_vars/all.yml` to match your environment.

### Create Cluster

Start provisioning of the cluster using the following command:

```bash
ansible-playbook site.yml -i inventory/my-cluster/hosts.ini
```

After deployment control plane will be accessible via virtual ip-address which is defined in inventory/group_vars/all.yml as `apiserver_endpoint`

### Remove k3s cluster

```bash
ansible-playbook reset.yml -i inventory/my-cluster/hosts.ini
```

>You should also reboot these nodes due to the VIP not being destroyed

## Kube Config

To copy your `kube config` locally so that you can access your **Kubernetes** cluster run:

```bash
scp debian@master_ip:~/.kube/config ~/.kube/config
```

### Testing your cluster

See the commands [here](https://docs.technotim.live/posts/k3s-etcd-ansible/#testing-your-cluster).

### Troubleshooting

Be sure to see [this post](https://github.com/techno-tim/k3s-ansible/discussions/20) on how to troubleshoot common problems

### Testing the playbook using molecule

This playbook includes a [molecule](https://molecule.rtfd.io/)-based test setup.
It is run automatically in CI, but you can also run the tests locally.
This might be helpful for quick feedback in a few cases.
You can find more information about it [here](molecule/README.md).

## Thanks

This repo is really standing on the shoulders of giants. Thank you to all those who have contributed and thanks to these repos for code and ideas:

- [techno-tim/k3s-ansible](https://github.com/techno-tim/k3s-ansible)
- [ricsanfre/pi-cluster](https://github.com/ricsanfre/pi-cluster)
