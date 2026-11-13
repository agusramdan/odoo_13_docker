FROM python:3.8.20-slim-bullseye

MAINTAINER Agus Ramdan <email@agusramdan.web.id>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Install system dependencies yang diperlukan Odoo 13 & psycopg2
RUN apt-get clean && apt-get update --fix-missing && apt-get install -y --fix-missing --no-install-recommends \
    build-essential \
    libpq-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libjpeg-dev \
    libfreetype6-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Install Python packages yang kompatibel dengan Odoo 13 di Python 3.8
RUN pip install --no-cache-dir \
    psycopg2-binary==2.8.6 \
    Babel==2.8.0 \
    chardet==3.0.4 \
    decorator==4.4.2 \
    docutils==0.16 \
    ebaysdk==2.1.5 \
    freezegun==0.3.15 \
    gevent==20.9.0 \
    greenlet==0.4.17 \
    idna==2.10 \
    Jinja2==2.11.3 \
    libsass==0.20.1 \
    lxml==4.6.3 \
    MarkupSafe==1.1.1 \
    num2words==0.5.10 \
    ofxparse==0.21 \
    passlib==1.7.4 \
    Pillow==8.3.2 \
    polib==1.1.0 \
    psutil==5.8.0 \
    pydot==1.4.2 \
    pyopenssl==20.0.1 \
    PyPDF2==1.26.0 \
    pyserial==3.5 \
    python-dateutil==2.8.1 \
    python-openid==2.2.5 \
    pytz==2021.1 \
    pyusb==1.2.1 \
    qrcode==6.1 \
    reportlab==3.5.68 \
    requests==2.25.1 \
    vobject==0.9.6.1 \
    Werkzeug==1.0.1 \
    xlrd==2.0.1 \
    xlsxwriter==1.4.3 \
    xlwt==1.3.0 \
    zeep==4.0.0

# Upgrade pip dan install debugpy
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir debugpy

ENV LANG=C.UTF-8

# Install dependencies dan wkhtmltopdf
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl dirmngr fonts-noto-cjk gnupg libssl-dev \
    node-less npm python3-num2words python3-pip python3-phonenumbers \
    python3-pyldap python3-qrcode python3-renderpm python3-setuptools \
    python3-slugify python3-vobject python3-watchdog python3-xlrd \
    python3-xlwt xz-utils \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb \
    && echo 'cecbf5a6abbd68d324a7cd6c51ec843d71e98951 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss
RUN npm install -g rtlcss

ENV ODOO_VERSION=13.0
ARG ODOO_RELEASE=20230601
ARG ODOO_SHA=b35f599424021c25a44eae44007b9c37421789bd

# Install Odoo
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
    && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
    && apt-get update \
    && apt-get -y install --no-install-recommends ./odoo.deb \
    && rm -rf /var/lib/apt/lists/* odoo.deb 
# Copy script & konfigurasi (File hash disesuaikan dengan file lokal biasanya)
COPY entrypoint.sh /
COPY odoo.conf /etc/odoo/

# Atur permission
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

EXPOSE 8069 8071 8072

ENV ODOO_RC=/etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

USER odoo

ENTRYPOINT ["/entrypoint.sh"]

CMD ["odoo"]

