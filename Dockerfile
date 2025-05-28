# use python 3.11 slim as the base
from python:3.11-slim

# prevent interactive prompts during apt-get install
env debian_frontend=noninteractive

# install system dependencies
run apt-get update && apt-get install -y --no-install-recommends \
  # common tools
  bash zsh git curl vim sudo \
  ca-certificates \
  # c/c++ build dependencies (often needed for native python packages)
  build-essential \
  cmake \
  ninja-build \
  # python build tool (though uv handles much, patchelf can be useful)
  patchelf \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# install uv (from official astral-sh image)
copy --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# set up oh my zsh and plugins
run \
    # install fzf (often used with zsh)
    git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf && \
    /root/.fzf/install --all && \
    # install oh my zsh non-interactively
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # configure .zshrc for plugins
    sed -i 's/plugins=(git)/plugins=(fzf)/g' /root/.zshrc && \
    # clone custom plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    # set zsh theme and disable auto-updates
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="minimal"/g' /root/.zshrc && \
    echo "zstyle ':omz:update' mode disabled" >> /root/.zshrc

# create the project's virtual environment and pre-install dependencies
# copy only pyproject.toml (and optionally a lock file if you use one)
copy ./pyproject.toml /tmp_setup/pyproject.toml
# if you use a uv.lock file for pinned dependencies, copy it too:
# copy ./uv.lock /tmp_setup/uv.lock

run \
    # create the virtual environment
    uv venv /opt/venv --python python3.11 && \
    # compile pyproject.toml to a requirements file to install *only* dependencies
    # this avoids installing the "dumpulator" package itself from this temporary context
    echo "compiling dependencies from /tmp_setup/pyproject.toml..." && \
    uv pip compile /tmp_setup/pyproject.toml --output-file /tmp_setup/requirements.txt --python /opt/venv/bin/python && \
    # if you want to include 'dev' dependencies (like libclang):
    # uv pip compile /tmp_setup/pyproject.toml --extra dev --output-file /tmp_setup/requirements.txt --python /opt/venv/bin/python
    echo "installing compiled dependencies into /opt/venv..." && \
    uv pip sync --python /opt/venv/bin/python /tmp_setup/requirements.txt && \
    # list installed packages for verification (optional, good for debugging)
    echo "installed packages in /opt/venv:" && \
    uv pip list --python /opt/venv/bin/python && \
    # clean up
    rm -rf /tmp_setup

# set environment variables to activate the virtual environment globally
# this is the primary way the venv is "activated" for all processes in the container.
ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"

# copy the entrypoint script and make it executable
copy ./entrypoint.sh /usr/local/bin/entrypoint.sh
run chmod +x /usr/local/bin/entrypoint.sh

# set working directory for the container
workdir /prj

# use the entrypoint to handle editable install before launching the command
entrypoint ["/usr/local/bin/entrypoint.sh"]

# default to zsh shell (as a login shell to source .zshrc)
cmd ["/bin/zsh", "-l"]