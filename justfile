set export

DEBIAN_FRONTEND := "noninteractive"
PYTHON_VERSION := "3.11.3"
R_VERSION := "4.3.0"
OS_ERROR_MESSAGE := "Unkown operating system. Opearting system must be one of: (1) Ubuntu 22.04 [Jammy], (2) RHEL 8"

OS := if `cat /etc/*release | { grep -ic 'DISTRIB_RELEASE=22.04' || true; }` == "1"  {
    "ubuntu-22"
} else if `cat /etc/*release | { grep -ic 'PLATFORM_ID="platform:el8"' || true; }` == "1" {
    "rhel-8"
} else {
    error(OS_ERROR_MESSAGE)
}

WORKBENCH_INSTALLER := if OS == "ubuntu-22" {
    "https://download2.rstudio.org/server/jammy/amd64/rstudio-workbench-2023.03.1-446.pro1-amd64.deb"
} else if OS == "rhel-8" {
    "https://download2.rstudio.org/server/rhel8/x86_64/rstudio-workbench-rhel-2023.03.1-446.pro1-x86_64.rpm"
} else {
    error(OS_ERROR_MESSAGE)
}

CONNECT_INSTALLER := if OS == "ubuntu-22" {
    "https://cdn.rstudio.com/connect/2023.05/rstudio-connect_2023.05.0~ubuntu22_amd64.deb"
} else if OS == "rhel-8" {
    "https://cdn.rstudio.com/connect/2023.05/rstudio-connect-2023.05.0.el8.x86_64.rpm"
} else {
    error(OS_ERROR_MESSAGE)
}

PACKAGE_MANAGER_INSTALLER := if OS == "ubuntu-22" {
    "https://cdn.posit.co/package-manager/ubuntu22/amd64/rstudio-pm_2023.04.0-6_amd64.deb"
} else if OS == "rhel-8" {
    "https://cdn.posit.co/package-manager/rhel8/x86_64/rstudio-pm-2023.04.0-6.x86_64.rpm"
} else {
    error(OS_ERROR_MESSAGE)
}

R_REPO_URL := if OS == "ubuntu-22" {
    "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
} else if OS == "rhel-8" {
    "https://packagemanager.posit.co/cran/__linux__/centos8/latest"
} else {
    error(OS_ERROR_MESSAGE)
}


default:
    @just --list

# ------------------------------------------------------------------------------
# Init
# ------------------------------------------------------------------------------

# Install commonly used system dependencies
init:
    #!/bin/bash
    set -e
    if [ "$OS" = 'ubuntu-22' ]; then
        if [ -f /.dockerenv ]; then apt-get update && apt-get install -y sudo; else sudo apt-get update; fi
        sudo apt-get install -y vim curl gdebi-core
    elif [ "$OS" = 'rhel-8' ]; then
        if [ -f /.dockerenv ]; then yum install -y sudo; fi
        yum install -y vim curl
        # Enable the Extra Packages for Enterprise Linux (EPEL) repository
        sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
        # Enable the CodeReady Linux Builder repository: On Premise || Public Cloud || Error condition
        sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms || \
            sudo dnf install dnf-plugins-core && sudo dnf config-manager --set-enabled "codeready-builder-for-rhel-8-*-rpms" || \
            echo "CodeReady Linux Builder repository not enabled!"
    fi

# ------------------------------------------------------------------------------
# Install R
# ------------------------------------------------------------------------------

install-r:
    #!/bin/bash
    set -e
    if [ "$OS" = 'ubuntu-22' ]; then
        just install-r-ubuntu-22
    elif [ "$OS" = 'rhel-8' ]; then
        just install-r-rhel-8
    fi

[private]
install-r-ubuntu-22:
    curl -O https://cdn.rstudio.com/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb
    sudo -E gdebi -n r-${R_VERSION}_1_amd64.deb
    /opt/R/${R_VERSION}/bin/R --version

[private]
install-r-rhel-8:
    curl -O https://cdn.rstudio.com/r/centos-8/pkgs/R-${R_VERSION}-1-1.x86_64.rpm
    sudo yum install -y R-${R_VERSION}-1-1.x86_64.rpm
    /opt/R/${R_VERSION}/bin/R --version

symlink-r:
    sudo ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R
    sudo ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# ------------------------------------------------------------------------------
# Install Python
# ------------------------------------------------------------------------------

install-python:
    #!/bin/bash
    set -e
    if [ "$OS" = 'ubuntu-22' ]; then
        just install-python-ubuntu-22
    elif [ "$OS" = 'rhel-8' ]; then
        just install-python-rhel-8
    fi

[private]
install-python-ubuntu-22:
    curl -O https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb
    sudo gdebi -n python-${PYTHON_VERSION}_1_amd64.deb
    /opt/python/"${PYTHON_VERSION}"/bin/python --version
    /opt/python/"${PYTHON_VERSION}"/bin/pip install --upgrade pip setuptools wheel

[private]
install-python-rhel-8:
    curl -O https://cdn.rstudio.com/python/centos-8/pkgs/python-${PYTHON_VERSION}-1-1.x86_64.rpm
    sudo yum install -y python-${PYTHON_VERSION}-1-1.x86_64.rpm
    /opt/python/"${PYTHON_VERSION}"/bin/python --version
    /opt/python/"${PYTHON_VERSION}"/bin/pip install --upgrade pip setuptools wheel

# ------------------------------------------------------------------------------
# Install Workbench
# ------------------------------------------------------------------------------

install-workbench:
    #!/bin/bash
    set -e
    if [ "$OS" = 'ubuntu-22' ]; then
        just install-workbench-ubuntu-22
    elif [ "$OS" = 'rhel-8' ]; then
        just install-workbench-rhel-8
    fi

    # Install R
    if [ -f /opt/R/${R_VERSION}/bin/R ]; then echo just install-r; fi

    # Install Python
    if [ -f /opt/python/${PYTHON_VERSION}/bin/python ]; then echo just install-python; fi

    # Install Jupyter
    sudo /opt/python/${PYTHON_VERSION}/bin/pip install jupyter jupyterlab rsp_jupyter rsconnect_jupyter workbench_jupyterlab
    sudo /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsp_jupyter
    sudo /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsp_jupyter
    sudo /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsconnect_jupyter
    sudo /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsconnect_jupyter
    sudo /opt/python/${PYTHON_VERSION}/bin/jupyter-serverextension enable --sys-prefix --py rsconnect_jupyter

    sudo tee /etc/rstudio/jupyter.conf <<EOF
    jupyter-exe=/opt/python/${PYTHON_VERSION}/bin/jupyter
    notebooks-enabled=1
    labs-enabled=1
    default-session-cluster=Local
    EOF
    
    sudo tee /etc/rstudio/repos.conf <<EOF
    CRAN=${R_REPO_URL}
    RSPM=${R_REPO_URL}
    EOF

    if [ -f /.dockerenv ]; then
        echo "In Docker, not restarting" 
    else 
        sudo systemctl restart rstudio-server
        sudo systemctl restart rstudio-launcher
    fi

[private]
install-workbench-ubuntu-22:
    curl -f -o "workbench.deb" "$WORKBENCH_INSTALLER"
    sudo gdebi -n "workbench.deb"

[private]
install-workbench-rhel-8:
    curl -f -o "workbench.rpm" "$WORKBENCH_INSTALLER"
    sudo yum install -y "workbench.rpm"

# ------------------------------------------------------------------------------
# Install Connect
# ------------------------------------------------------------------------------

install-connect:
    #!/bin/bash
    set -e
    if [ "$OS" = 'ubuntu-22' ]; then
        just install-connect-ubuntu-22
    elif [ "$OS" = 'rhel-8' ]; then
        just install-connect-rhel-8
    fi

    sudo tee /etc/rstudio-connect/rstudio-connect.gcfg <<EOF
    [Server]
    ; Address = "http://posit-connect.example.com"
    ; SenderEmail = "no-reply@example.com"
    ; EmailProvider = "SMTP"
    ; EmailProvider = "sendmail"
    
    ; [SMTP]
    ; Host = "smtp.example.com"
    ; Port = 587
    ; SSL = false
    ; StartTLS = "detect"
    ; User = "no-reply@example.com"
    ; Password = "secret"
    
    [HTTP]
    Listen = ":3939"

    [Authentication]
    Provider = "password"

    [RPackageRepository "CRAN"]
    URL = "{{R_REPO_URL}}"

    [RPackageRepository "RSPM"]
    URL = "{{R_REPO_URL}}"
    
    [Python]
    Enabled = true
    Executable = /opt/python/${PYTHON_VERSION}/bin/python
    EOF

    if [ -f /.dockerenv ]; then
        echo "In Docker, not restarting" 
    else 
        sudo systemctl restart rstudio-connect
    fi

[private]
install-connect-ubuntu-22:
    curl -f -o "connect.deb" "$CONNECT_INSTALLER"
    sudo gdebi -n "connect.deb"

[private]
install-connect-rhel-8:
    curl -f -o "connect.rpm" "$CONNECT_INSTALLER"
    sudo yum install -y "connect.rpm"

# ------------------------------------------------------------------------------
# Install Package Manager
# ------------------------------------------------------------------------------

install-package-manager:
    #!/bin/bash
    set -e
    if [ "$OS" = 'ubuntu-22' ]; then
        just install-package-manager-ubuntu-22
    elif [ "$OS" = 'rhel-8' ]; then
        just install-package-manager-rhel-8
    fi

    sudo tee /etc/rstudio-pm/rstudio-pm.gcfg <<EOF
    [Server]
    Address =
    RVersion = /opt/R/${R_VERSION}/

    [HTTP]
    Listen = :4242

    [HTTPS]
    ; Certificate = ""
    ; Key = ""

    [CRAN]
    ; SyncSchedule = "0 0 * * *"

    [Bioconductor]
    ;SyncSchedule = "0 2 * * *"

    [PyPI]
    ;SyncSchedule = "0 1 * * *"
.
    [Git]
    ; PollInterval = 5m
    ; BuildRetries = 3
    EOF

    if [ -f /.dockerenv ]; then
        echo "In Docker, not restarting" 
    else 
        sudo systemctl restart rstudio-pm
    fi


[private]
install-package-manager-ubuntu-22:
    curl -f -o "package-manager.deb" "$PACKAGE_MANAGER_INSTALLER"
    sudo gdebi -n "package-manager.deb"

[private]
install-package-manager-rhel-8:
    curl -f -o "package-manager.rpm" "$PACKAGE_MANAGER_INSTALLER"
    sudo yum install -y "package-manager.rpm"

# ------------------------------------------------------------------------------
# Utilities
# ------------------------------------------------------------------------------

install-docker:
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh ./get-docker.sh