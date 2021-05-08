FROM mcr.microsoft.com/vscode/devcontainers/base:buster

ARG USERNAME=vscode

# Set these in devcontainer.json
ARG TERRAFORM_VERSION
ARG TERRAFORM_CHECKSUM
ARG TERRAGRUNT_VERSION
ARG TERRAGRUNT_CHECKSUM
ARG TFSEC_VERSION
ARG TFSEC_CHECKSUM

# Install packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends awscli ca-certificates curl git gnupg2 jq make nano openssh-client zsh \
    && apt-get autoremove -y && apt-get clean -y 

# Install Terraform
RUN curl -Lo terraform.zip https://releases.hashicorp.com/terraform/"${TERRAFORM_VERSION}"/terraform_"${TERRAFORM_VERSION}"_linux_"$(dpkg --print-architecture)".zip \
    && echo "${TERRAFORM_CHECKSUM} terraform.zip" | sha256sum --check \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install Terragrunt
RUN curl -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v"${TERRAGRUNT_VERSION}"/terragrunt_linux_"$(dpkg --print-architecture)" \
    && echo "${TERRAGRUNT_CHECKSUM} terragrunt" | sha256sum --check \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/

# Install tfsec
RUN curl -Lo tfsec https://github.com/tfsec/tfsec/releases/download/v"${TFSEC_VERSION}"/tfsec-linux-"$(dpkg --print-architecture)" \
    && echo "${TFSEC_CHECKSUM} tfsec" | sha256sum --check \
    && chmod +x tfsec \
    && mv tfsec /usr/local/bin/    

# Setup aliases and autocomplete
RUN echo "\n\
complete -C /usr/bin/aws_completer aws\n\
complete -C /usr/local/bin/terraform terraform\n\
complete -C /usr/local/bin/terraform terragrunt\n\
alias tf='terraform'\n\
alias tg='terragrunt'\n\
alias ll='la -la'" >> /home/"${USERNAME}"/.zshrc