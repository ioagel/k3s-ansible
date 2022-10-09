# Test suites for `k3s-ansible`

This folder contains the [molecule](https://molecule.rtfd.io/)-based test setup for this playbook.

## Scenarios

We have these scenarios:

- **default**:
  A 3 control + 2 worker node cluster based very closely on the  [sample inventory](../inventory/sample).
- **single_node**:
  Very similar to the default scenario, but uses only a single node for all cluster functionality.

## How to execute

To test on your local machine, follow these steps:

### System requirements

Make sure that the following software packages are available on your system:

- [Python 3](https://www.python.org/downloads)
- [Vagrant](https://www.vagrantup.com/downloads) with `libvirt`(Linux) or `virtualbox`(Mac or Windows) providers
  - For Linux only, `libvirt` is the default. Run `export VAGRANT_PROVIDER_NAME=virtualbox` in terminal to force `virtualbox` provider.
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) and/or **KVM**
- (optional) [k9s](https://k9scli.io/) cli to inspect/manage k8s clusters

For `Linux` install `kvm` instead of `virtualbox` and vagrant `libvirt` plugin, for better experience.

Vagrant boxes used to test RedHat derivatives and Ubuntu:
- generic/ubuntu2204
- generic/debian11
- generic/centos9s
- generic/rocky9
- generic/alma9

### Set up VirtualBox networking on Linux and macOS

_You can safely skip this if you are working on Windows._

Furthermore, the test cluster uses the `192.168.30.0/24` subnet which is [not set up by VirtualBox automatically](https://www.virtualbox.org/manual/ch06.html#network_hostonly).
To set the subnet up for use with VirtualBox, please make sure that `/etc/vbox/networks.conf` exists and that it contains this line:

```
* 192.168.30.0/24
```

### Install Python dependencies

You will get [Molecule, Ansible and a few extra dependencies](../requirements.txt) via [pip](https://pip.pypa.io/).
Usually, it is advisable to work in a [virtual environment](https://docs.python.org/3/tutorial/venv.html) for this:

```bash
cd /path/to/k3s-ansible

# Create a virtualenv at ".env". You only need to do this once.
python3 -m venv .env

# Activate the virtualenv for your current shell session.
# If you start a new session, you will have to repeat this.
source .env/bin/activate

# Install the required packages into the virtualenv.
# These remain installed across shell sessions.
python3 -m pip install -r requirements.txt
```

### Run molecule scenarios with make

With the virtual environment from the previous step active in your shell session, you can now use molecule to test the playbook.
Interesting commands for the `default` scenario:

- `make mol-create`: Create virtual machines for the test cluster nodes.
- `make mol-conv`: Run the `site` playbook on the nodes of the test cluster.
- `make mol-ver`: Verify that the cluster works correctly.
- `make mol-side`: Run the `reset` playbook on the nodes of the test cluster.
- `make mol-destroy`: Delete the virtual machines for the test cluster nodes.
- `make mol`: The "all-in-one" sequence of steps that is executed in CI.
  This includes the `create`, `converge`, `verify`, `side-effect` and `destroy` steps.
  See [`molecule.yml`](default/molecule.yml) for more details.

For TDD like experience for the `default` scenario:
- `make mol-conv` (converge) This will also download from the first master the `kubeconfig` file that you can use to connect to the cluster. Instructions are provided by running the target.
- `make mol-ver` (verify)

Rinse and repeat.

Check the [Makefile](../Makefile) for additional targets and help.

If you have installed `k9s`, use `./k9s.sh default|single|three` to inspect your cluster.
