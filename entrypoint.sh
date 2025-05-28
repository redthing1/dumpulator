#!/bin/bash
set -e # exit immediately if a command exits with a non-zero status.

# the virtual environment is activated by env variables set in the dockerfile.

if [ -f "/prj/pyproject.toml" ]; then
    # echo "entrypoint: found pyproject.toml in /prj. attempting editable install of mounted project..."
    cd /prj
    uv pip install -e . --python /opt/venv/bin/python
    # echo "entrypoint: editable install of mounted project attempted."
else
    # echo "entrypoint: no pyproject.toml found in /prj. skipping editable install."
    # echo "entrypoint: using pre-installed version of the project from the image."
    true
fi

# execute the docker cmd (e.g., /bin/zsh -l)
exec "$@"