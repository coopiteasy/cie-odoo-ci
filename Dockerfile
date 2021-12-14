ARG codename=focal

FROM ubuntu:$codename
ENV LANG C.UTF-8
USER root

ARG python_version="3.7"

# Basic dependencies
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends \
        ca-certificates \
        curl \
        gettext \
        gnupg \
        lsb-release \
        software-properties-common \
        expect-dev \
        postgresql-client \
        firefox

# Install wkhtml
RUN curl -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_amd64.deb -o /tmp/wkhtml.deb \
    && apt-get update -qq \
    && dpkg --force-depends -i /tmp/wkhtml.deb \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -f --no-install-recommends \
    && rm /tmp/wkhtml.deb

# Install nodejs dependencies
RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo "deb https://deb.nodesource.com/node_15.x `lsb_release -c -s` main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq nodejs

# Get latest version of Git
RUN add-apt-repository -y ppa:git-core/ppa \
    && apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq git

# Make all Python versions available
RUN add-apt-repository -y ppa:deadsnakes/ppa

# Install build dependencies for python libs commonly used by Odoo and OCA
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends \
       build-essential \
       python$python_version-dev \
       python3 \
       python3-venv \
       # for psycopg
       libpq-dev \
       # for lxml
       libxml2-dev \
       libxslt1-dev \
       libz-dev \
       libxmlsec1-dev \
       # for python-ldap
       libldap2-dev \
       libsasl2-dev \
       # need libjpeg to build older pillow versions
       libjpeg-dev \
       # for pycups
       libcups2-dev \
       # some libs need swig
       swig \
       # PyYAML for own scripts
       python3-yaml

# Install pipx, which we use to install other python tools.
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_DEFAULT_PYTHON=/usr/bin/python3
RUN python3 -m venv /opt/pipx-venv \
    && /opt/pipx-venv/bin/pip install --no-cache-dir pipx \
    && ln -s /opt/pipx-venv/bin/pipx /usr/local/bin/

# We don't use the ubuntu virtualenv package because it unbundles pip dependencies
# in virtualenvs it create.
RUN pipx install --pip-args="--no-cache-dir" virtualenv

# We use manifestoo to check licenses, development status
RUN pipx install --pip-args="--no-cache-dir" "manifestoo>=0.3.1"

# Install the 'addons' helper script
# TODO: use manifestoo
RUN pipx install --pip-args="--no-cache-dir" acsoo==3.0.2
# COPY bin/addons /usr/local/bin

# Install setuptools-odoo-get-requirements and setuptools-odoo-makedefault helper
# scripts.
RUN pipx install --pip-args="--no-cache-dir" "setuptools-odoo>=3.0.1"

# Install git-aggregator
RUN pipx install --pip-args="--no-cache-dir" git-aggregator==2.1.0

# Make scripts available
COPY bin/* /usr/local/bin/

# Gitaggregate
RUN /usr/local/bin/refresh_gitaggregate.py

# Make a virtualenv for Odoo so we isolate from system python dependencies and
# make sure addons we test declare all their python dependencies properly
RUN virtualenv -p python$python_version /opt/odoo-venv \
    && /opt/odoo-venv/bin/pip install --no-cache-dir "setuptools<58.0.0" "pip>=21.3.1;python_version>='3.6'" \
    && /opt/odoo-venv/bin/pip list
ENV PATH=/opt/odoo-venv/bin:$PATH

ARG odoo_version=12.0

# Install Odoo requirements (use ADD for correct layer caching).
# We use requirements from OCB for easier maintenance of older versions.
# We use no-binary for psycopg2 because its binary wheels are sometimes broken
# and not very portable.
ADD https://raw.githubusercontent.com/OCA/OCB/$odoo_version/requirements.txt /tmp/ocb-requirements.txt
RUN pip install --no-cache-dir --no-binary psycopg2 -r /tmp/ocb-requirements.txt

# Install other test requirements.
# - coverage
# - websocket-client is required for Odoo browser tests
# - odoo-autodiscover required for python2
RUN pip install --no-cache-dir \
  coverage \
  websocket-client \
  "odoo-autodiscover>=2 ; python_version<'3'"

# Install Odoo (use ADD for correct layer caching)
# ARG odoo_org_repo=odoo/odoo
# ADD https://api.github.com/repos/$odoo_org_repo/git/refs/heads/$odoo_version /tmp/odoo-version.json
# RUN mkdir /tmp/getodoo \
#     && (curl -sSL https://github.com/$odoo_org_repo/tarball/$odoo_version | tar -C /tmp/getodoo -xz) \
#     && mv /tmp/getodoo/* /opt/odoo \
#     && rmdir /tmp/getodoo
# RUN pip install --no-cache-dir -e /opt/odoo \
#     && pip list

# Install Odoo
RUN pip install --no-cache-dir -e /src/odoo \
    && pip list

# Copy over odoo.cfg
COPY odoo.cfg /etc/odoo.cfg
ENV ODOO_RC=/etc/odoo.cfg
ENV OPENERP_SERVER=/etc/odoo.cfg

ENV ODOO_VERSION=$odoo_version
ENV PGHOST=postgres
ENV PGUSER=odoo
ENV PGPASSWORD=odoo
ENV PGDATABASE=odoo
# This PEP 503 index uses odoo addons from OCA and redirects the rest to PyPI,
# in effect hiding all non-OCA Odoo addons that are on PyPI.
# ENV PIP_INDEX_URL=https://wheelhouse.odoo-community.org/oca-simple-and-pypi
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_PYTHON_VERSION_WARNING=1
# Control addons discovery. INCLUDE and EXCLUDE are comma-separated list of
# addons to include (default: all) and exclude (default: none)
# ENV ADDONS_DIR=.
# ENV INCLUDE=
# ENV EXCLUDE=
# ENV OCA_GIT_USER_NAME=oca-ci
# ENV OCA_GIT_USER_EMAIL=oca-ci@odoo-community.org
