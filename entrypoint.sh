#!/bin/bash
set -e # exit immediately if a command exits with a non-zero status.

# the virtual environment is activated by env variables set in the dockerfile.
# (path="/opt/venv/bin:$path" and virtual_env="/opt/venv")

# echo "entrypoint: checking for project in /prj..."

if [ -f "/prj/pyproject.toml" ]; then
    # echo "entrypoint: found pyproject.toml in /prj. attempting editable install..."
    cd /prj
    # install the project in editable mode.
    # dependencies should already be satisfied by the pre-built venv.
    # uv should be smart enough not to re-download/re-build already compliant deps.
    # using --no-deps might be too aggressive if the pyproject.toml in /prj
    # has slightly different versions than what was used for pre-installing,
    # but for this setup, we assume the core dependencies are already there.
    # let's try without --no-deps first, as uv handles this well.
    uv pip install -e . --python /opt/venv/bin/python
    # echo "entrypoint: editable install attempted."
else
    echo "entrypoint: no pyproject.toml found in /prj. skipping editable install."
    echo "entrypoint: your project's packages might not be importable unless added to pythonpath or cwd."
fi

# execute the docker cmd (e.g., /bin/zsh -l)
exec "$@"