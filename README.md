# Building a REST instance

## Configuration

You need the following repos checked out:

* [ensembl-rest-deploy](https://github.com/Ensembl/ensembl-rest-deploy)
* [ensembl-rest_private](https://github.com/Ensembl/ensembl-rest_private)
* [lairdm/ansible-perlbrew](https://github.com/lairdm/ansible-perlbrew)

The shell variable REPO_HOME should point to where these repos are checked out.

ansible-perlbrew should be inside the root of ensembl-rest-deploy.

## Create VM

Create a VM according to the SOP, use the file cloudinit.cfg as the "User Data" field to seed the cloud-init when the machine is built. Note down the IP of the VM when it's launched.

The cloud-init will update the VM, install some minimal packages, and do a reboot.  So it should take about 90 seconds to fully boot.

## SSH configuration

You need an ssh configuration similar to

```
Host rest.ensembl.org
  User ubuntu
  IdentityFile ~/.ssh/rest.pem
  ForwardX11 yes
  ForwardX11Trusted yes
  Compression yes
  CompressionLevel 5

Host 192.168.0.*
  HostName %h
  User ubuntu
  ProxyCommand ssh -W %h:%p rest.ensembl.org
  IdentityFile ~/.ssh/rest.pem
  StrictHostKeyChecking no

```

Where you have your private key on the rest.ensembl.org host is up to you.

## Configure deployment

In the ensembl-rest_private repository you'll find a release.yml file under each set of configurations. This needs to be set with the release number and locations for files on the deployment environment. Once configured, ensembl-rest_private should branched (not not already) for that release and pushed to github.

## Configuring facts

There are a number of configurable facts that can be overridden when running the play, these can be seen in vars/main.yml. But briefly, the important ones are:

ensembl_user (default: ensembl)
ensembl_group (default: ensembl)

To override these, add them to the -e option for ansible-playbook, ie.

  ansible-playbook -e "ensembl_user=ubuntu ..."

## Running Ansible

You'll need at least Ansible 2.1 running on your local machine. Virtualenv is a great tool for keeping this install separate from your system python. Then to deploy the REST server, pick one of the following commands. Substitute the IP from the VM creation step for the one in the command below.

Build without installing the system packages:

  ansible-playbook -e "rest_private_dir=$REPO_HOME/ensembl-rest_private/rest.ensembl.org ensembl_repo_version=release/87" -i "192.168.0.141," playbook.yml

Build with installing the system packages:

  ansible-playbook -e "rest_private_dir=$REPO_HOME/ensembl-rest_private/rest.ensembl.org ensembl_repo_version=release/87 install_system=True" -i "192.168.0.141," playbook.yml

Build with installing the system packages and configuring the Embassy OpenStack environment:

  ansible-playbook -e "rest_private_dir=$REPO_HOME/ensembl-rest_private/rest.ensembl.org ensembl_repo_version=release/87 install_system=True embassy_config=True" -i "192.168.0.141," playbook.yml

# Building the Ensembl VM

You will need [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) and Virtualbox installed. As well, you will need the following repos checked out:

* [ensembl-rest-deploy](https://github.com/Ensembl/ensembl-rest-deploy)
* [boxcutter](https://github.com/boxcutter/ubuntu.git)

Set the DEPLOY_BASE to the vm/ directory in the ensembl-rest-deploy repo and version

  export DEPLOY_BASE=/some/directory/ensembl-rest-deploy/vm
  export RELEASE=88

Edit the installation script in ensembl-rest-deploy to use the correct version of Ensembl for the VM you're building

  emacs ${DEPLOY_BASE}/ensembl.sh

and change the repo variable to the git tag to use for all Ensembl repos, eg.

  REPO=release/88

Then simply run the packer script using the custom configuration from ensembl-rest-deploy:

  packer build -only=virtualbox-iso -var-file=${DEPLOY_BASE}/ensembl.json -var "version=${RELEASE}" -var "custom_script=${DEPLOY_BASE}/ensembl.sh" -var "vagrantfile_template=${DEPLOY_BASE}/vagrantfile-ensembl.tpl" ubuntu.json

Once the build finishes, add the box to vagrant then start the box.

  vagrant box add ensembl/ensembl box/virtualbox/ensemblvm-${RELEASE}.box
  vagrant init ensembl/ensembl
  vagrant up

To export the VM for distribution, open virtualbox and under File->Export Applicance, follow the prompts and create an OVA. This can be distributed as usual.
