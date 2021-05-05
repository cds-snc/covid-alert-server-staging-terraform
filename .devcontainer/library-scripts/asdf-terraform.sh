#!/bin/zsh

. ~/.zshrc

cd server/aws

asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git
asdf plugin-add terragrunt https://github.com/lotia/asdf-terragrunt.git
asdf install
