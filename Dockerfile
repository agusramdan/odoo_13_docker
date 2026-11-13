FROM python:3.8.20-slim-bullseye

MAINTAINER Agus Ramdan <email@agusramdan.web.id>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV LANG=C.UTF-8

# Install dependencies dan wkhtmltopdf


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

