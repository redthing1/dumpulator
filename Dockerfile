FROM debian:bookworm-slim

# install dependencies
RUN apt update && apt install -y \
  # common build dependencies
  bash git curl ccache \
  # c++ build dependencies
  build-essential cmake ninja-build \
  # python build dependencies
  python3 python3-pip patchelf \
  && apt clean && rm -rf /var/lib/apt/lists/*

# install poetry for python
RUN curl -sSL https://install.python-poetry.org | python3 - \
  && echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc \
  && echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bash_profile

# cool shell
RUN apt update && apt install -y \
  zsh \
  && rm -rf /var/lib/apt/lists/* && apt autoremove -y && apt clean \
  && git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install \
  && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  # edit the config to add fzf to plugins
  && sed -i 's/plugins=(git)/plugins=(fzf)/g' /root/.zshrc \
  # install zsh-autosuggestions
  && git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
  # install zsh-syntax-highlighting
  && git clone https://github.com/zsh-users/zsh-syntax-highlighting /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
  # change the theme
  && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="cypher"/g' /root/.zshrc \
  # source bash profile in zsh
  && echo "source ~/.bash_profile" >> /root/.zshrc \
  && echo "Fancy shell installed"

# copy pyproject and install package
COPY ./pyproject.toml /prj/
COPY ./README.md /prj/
COPY ./src /prj/src/

RUN cd /prj && \
  bash -l -c 'poetry install --no-interaction'

# clean up so sources can be mounted
RUN rm -rf /prj/*

# set working directory
WORKDIR /prj

CMD ["/bin/zsh", "-l"]
