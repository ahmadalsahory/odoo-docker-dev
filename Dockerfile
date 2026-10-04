# Thin layer over the official Odoo image: extra Python packages plus the
# odoo-docker entrypoint and helper. Rebuilt automatically by `docker compose up --build`.
ARG ODOO_TAG=20
FROM odoo:${ODOO_TAG}

USER root

# Extra Python dependencies for your modules (see requirements.txt).
# The env var (rather than --break-system-packages) is understood by the newer pip
# in Odoo 18+ images and silently ignored by the older pip in the Odoo 17 image.
COPY requirements.txt /tmp/requirements.txt
RUN if grep -qvE '^\s*(#|$)' /tmp/requirements.txt; then \
        PIP_BREAK_SYSTEM_PACKAGES=1 pip3 install --no-cache-dir -r /tmp/requirements.txt; \
    fi \
    && rm /tmp/requirements.txt

COPY docker/entrypoint.sh /usr/local/bin/odoo-docker-entrypoint
COPY docker/odoo-docker.sh /usr/local/bin/odoo-docker
# Strip CR in case the files were checked out with Windows line endings.
RUN sed -i 's/\r$//' /usr/local/bin/odoo-docker-entrypoint /usr/local/bin/odoo-docker \
    && chmod 755 /usr/local/bin/odoo-docker-entrypoint /usr/local/bin/odoo-docker \
    && mkdir -p /mnt/enterprise-addons /mnt/third-party-addons /mnt/custom-addons /mnt/backups \
    && chown odoo /etc/odoo /mnt/enterprise-addons /mnt/third-party-addons /mnt/custom-addons /mnt/backups

USER odoo

ENTRYPOINT ["/usr/local/bin/odoo-docker-entrypoint"]
CMD ["odoo"]
