# use python 3.11 slim as the base
FROM python:3.11-slim

# prevent interactive prompts during apt-get install
ENV debian_frontend=noninteractive

# install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# set up oh my zsh and plugins
RUN \
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

# create the project's virtual environment, pre-install dependencies,
# and pre-install the project itself.

# copy project files needed for dependency compilation and for building the project itself.
# this includes pyproject.toml, the actual source code (src/), and readme.
COPY ./pyproject.toml /tmp_setup/pyproject.toml
COPY ./README.md /tmp_setup/README.md
COPY ./src /tmp_setup/src
COPY ./uv.lock /tmp_setup/uv.lock

RUN \
    # create the virtual environment
    uv venv /opt/venv --python python3.11 && \
    \
    # compile pyproject.toml to a requirements file to install *only* project dependencies
    echo "compiling project dependencies from /tmp_setup/pyproject.toml..." && \
    uv pip compile /tmp_setup/pyproject.toml --all-extras --output-file /tmp_setup/requirements.txt --python /opt/venv/bin/python && \
    \
    echo "installing compiled project dependencies into /opt/venv..." && \
    uv pip sync --python /opt/venv/bin/python /tmp_setup/requirements.txt && \
    \
    echo "dependencies installed. now pre-installing the project (e.g., dumpulator) from /tmp_setup..." && \
    # install the project itself (e.g., dumpulator) from the copied sources.
    # --no-deps is used because we've already synced the exact dependencies.
    # this will use the hatchling build backend as defined in pyproject.toml.
    uv pip install --no-deps --python /opt/venv/bin/python /tmp_setup/. && \
    \
    # list installed packages for verification (optional, good for debugging)
    echo "installed packages in /opt/venv (after project pre-install):" && \
    uv pip list --python /opt/venv/bin/python && \
    \
    # clean up
    rm -rf /tmp_setup

# set environment variables to activate the virtual environment globally
ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"

# copu the entrypoint script and make it executable
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# set working directory for the container
WORKDIR /prj

# use the entrypoint to handle editable install before launching the command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# default to zsh shell (as a login shell to source .zshrc)
CMD ["/bin/zsh", "-l"]