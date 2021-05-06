# Note: You can use any Debian/Ubuntu based image you want. 
FROM mcr.microsoft.com/vscode/devcontainers/base:buster

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Set these in devcontainer.json
ARG TERRAFORM_VERSION
ARG TERRAFORM_CHECKSUM
ARG TERRAGRUNT_VERSION
ARG TERRAGRUNT_CHECKSUM
ARG TFSEC_VERSION
ARG TFSEC_CHECKSUM

# Install needed packages and setup non-root user. Use a separate RUN statement to add your
# own dependencies. A user of "automatic" attempts to reuse an user ID if one already exists.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY .devcontainer/library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends awscli curl git gpg make \
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
complete -C /usr/local/bin/aws_completer aws\n\
complete -C /usr/local/bin/terraform terraform\n\
complete -C /usr/local/bin/terraform terragrunt\n\
alias tf='terraform'\n\
alias tg='terragrunt'\n\
alias ll='la -la'" >> /home/"${USERNAME}"/.zshrc