#!/bin/bash -eux
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Ensembl release tag to install
REPO=release/99

# We need basic build tools for ansible
apt-get install -y build-essential libssl-dev libffi-dev python-pip git

# Install Ansible
pip install ansible

# Clone the repo for doing the install
git clone https://github.com/Ensembl/ensembl-rest-deploy.git

# Clone the perlbrew repo for the install
cd ensembl-rest-deploy
#git clone https://github.com/lairdm/ansible-perlbrew.git

# Install Ensembl
sudo -u ensembl ansible-playbook -i "localhost," -e "ensembl_repo_version=$REPO install_system=True" desktop.yml --connection=local

# Remove the deploy repo
cd ..
rm -rf ensembl-rest-deploy
