# FSI Server Container Setup (v24.x)

[![FSI Server Logo](http://fsi-site.neptunelabs.com/fsi/server?type=image&source=images%2Ffsi-logos%2Ffsi_server.png&width=250&height=86&format=png)][FSIServer]

<p align="center">
  <a href="#what-is-fsi-server"><strong>What is FSI Server?</strong></a> ·
  <a href="#getting-started"><strong>Getting Started</strong></a> ·
  <a href="#configuration"><strong>Configuration</strong></a> ·
  <a href="#advanced-topics"><strong>Advanced Topics</strong></a> ·
  <a href="#licensing"><strong>Licensing</strong></a> ·
  <a href="#quick-reference"><strong>Quick Reference</strong></a>
</p>

---

## What is [FSI Server][FSIServer]?

FSI Server dynamically generates images in various formats, sizes, and qualities in real-time. Upload a single high-resolution source image, and FSI Server will deliver variations on-demand via HTTP queries. This eliminates the need for manual image preparation. FSI Server also includes a suite of viewers for easy integration into your websites.

## Getting Started

### Requirements

- **Architecture:** x86-64
- **RAM:** A minimum of 8 GB is recommended, with at least 2 GB per CPU thread. For large-scale production environments, 32 GB or more is advised.
- **Docker:** Docker Compose V2 or higher.

We strongly recommend users of older Tomcat/WAR installations to upgrade to this container-based setup for simplified management and updates.

### How to Use This Repository

This repository provides a `docker-compose` setup for running FSI Server.

**Start the server:**

```shell
docker compose up --build -d
```

**Stop the server:**

```shell
docker compose down
```

For more information on Docker, please refer to the [official documentation](https://docs.docker.com/compose/).

### Web Interface

Once the containers are running, you can access the FSI Server web interface. By default, it's available at:

- **https://localhost/** (with a self-signed certificate)

---

## Configuration

### `compose.yaml` and `.env`

The `compose.yaml` file orchestrates the necessary services, including [Apache Solr](https://solr.apache.org/) for search, [nginx](https://nginx.org/) for SSL termination, and [lsyncd](https://github.com/lsyncd/lsyncd) for synchronization. You can customize this setup, for example, by replacing nginx with another reverse proxy like [Caddy](https://caddyserver.com/) or [Traefik](https://traefik.io/).

The primary configuration is managed through the `.env` file. Adjust the paths and settings to match your environment.

| VARIABLE             | DESCRIPTION                                                            |
|----------------------|------------------------------------------------------------------------|
| `FSI_SERVER_IMAGE_TAG` | The FSI Server version to use.                                         |
| `NGINX_IMAGE_TAG`      | The version tag for the nginx container.                               |
| `FSI_CONFIG_PATH`      | Filesystem path for FSI Server configuration.                          |
| `NGINX_CONFIG_PATH`    | Path to nginx configuration and certificates.                          |
| `ASSET_PATH`           | Filesystem path for your source images and static assets.              |
| `STORAGE_PATH`         | Filesystem path for optimized, real-time-ready images.                 |
| `OVERLAY_PATH`         | Configuration folder for FSI Viewer settings.                          |
| `SOLR_PATH`            | Path for the FSI Server Solr core index.                               |
| `SOLR_SERVER_URI`      | HTTP path to the Apache Solr server.                                   |
| `LOG_PATH`             | Central directory for all log files.                                   |
| `LOG_FSI_LEVEL`        | Log output verbosity for the FSI Server.                               |
| `SYNC_KEY`             | Path to the lsyncd private key for synchronization.                    |
| `MIRROR_HOSTNAME`      | Domain name or IP of the mirror server.                                |
| `MIRROR_SSH_PORT`      | SSH port of the mirror server.                                         |

### Directory Structure

- **`conf/fsi-server/`**: Contains all FSI Server settings. The container requires write access to this directory.
  - `settings.yml`: Basic server settings (leave untouched for container installations).
  - `users.yml`: User definitions and credentials.
  - `groups.yml`: User group and permission assignments.
  - `permissionsets.yml`: Permission definitions for groups and connectors.
  - `interface.yml`: Web interface settings.
  - `headers.yml`: Presets for HTTP header overrides.
  - `connectors/*.yml`: Maps local filesystem paths to URL-addressable paths in FSI Server.
  - `renderers/*.yml`: Encoder presets for image rendering.

- **`conf/nginx/`**: Configuration for the nginx container. Includes self-signed certificates for `localhost` to get you started.

- **`conf/lsyncd/`**: Configuration for the lsyncd container, used for mirror server synchronization.

- **`fsi-data/assets/`**: Default location for your source images and static files. This path is configurable via the `ASSET_PATH` variable.

- **`fsi-data/storage/`**: (Created on start) Stores optimized versions of your assets. This directory is mandatory for persistence and can grow to a similar size as your asset folders.

- **`fsi-data/solr-core/`**: Contains the Solr core for FSI Server's internal search. It will be recreated on restart if not present.

- **`fsi-data/overlay/`**: (Created on start) Stores presets and skins for the FSI Viewer.

- **`fsi-data/logs/`**: (Created on start) Central location for FSI Server, nginx, and lsyncd logs.

- **`container/`**: Contains Dockerfiles for building the nginx, lsync, and benchmark containers. Modifications are typically not needed.

### Where to Put My Pictures?

For testing, you can place your images in `fsi-data/assets/images` and static files (e.g., videos, PDFs) in `fsi-data/assets/statics`. For production, store your assets in a location suitable for your backup and synchronization strategy. Then, update or create new connectors in `conf/fsi-server/connectors` to map to your asset locations.

### Kubernetes

FSI Server can also be deployed in a Kubernetes environment. Ensure that the asset and storage volumes are connected as efficiently as possible, potentially using local storage nodes for performance. If using S3-based storage (e.g., via `s3fs-fuse` or `mountpoint-s3`), we recommend running benchmarks before going live.

---

## Advanced Topics

### Synchronization with `lsyncd`

For high-availability setups with multiple image servers, you need to synchronize assets and configurations. This repository includes a `compose-with-mirror.yaml` file that uses **lsyncd** for this purpose.

**Setup:**
1.  Ensure the target server has `ssh` and `rsync` installed.
2.  Generate an SSH key for authentication.
    ```shell
    ssh-keygen -t ed25519 -q -N "" -o -C "fsi-sync-key@$(hostname)" -f ./conf/lsyncd/sync.key
    ssh-copy-id -i ./conf/lsyncd/sync.key user@fsi-secondary.domain.tld
    ```
3.  Update `MIRROR_HOSTNAME` in your `.env` file.
4.  Customize synchronization paths in `conf/lsyncd/lsyncd.conf.lua` if your directory structure differs.
5.  Restart the lsyncd container: `docker restart lsyncd` and check the logs: `docker logs -f lsyncd`.

**Important:** Do **not** synchronize the `storage` directory. While technically possible, it can lead to cache inconsistencies and errors on the mirror servers. Each server should build its own storage.

### Backup

A solid backup strategy is crucial.
- **Essential:** Back up the `conf/fsi-server` directory, which contains your license, users, and connectors.
- **Recommended:** Also back up `$OVERLAY_PATH` and `$STORAGE_PATH/metadata`.
- **Optional:** The search index (`solr-core`) does not need to be backed up as it can be rebuilt automatically.

Backing up the entire `storage` directory depends on your recovery time objectives. Rebuilding the storage for a large number of images can be time-consuming.

### Nginx and SSL/TLS Certificates

The provided nginx configuration is ready for use with [Let's Encrypt](https://letsencrypt.org/).
1.  Ensure [certbot](https://certbot.eff.org/) is installed on your host system.
2.  Create a directory for the ACME challenge: `mkdir ./conf/nginx/acme`.
3.  Run certbot to obtain a certificate:
    ```shell
    certbot certonly --webroot \
    -w ./conf/nginx/acme \
    -d fsi.domain.tld \
    --agree-tos \
    -m my@email.tld
    ```
4.  Mount the Let's Encrypt directory into the nginx container by updating `compose.yaml`.
5.  Update `conf/nginx/sites/fsi-server.conf` to point to your new certificate files.

### Bottlenecks

FSI Server is highly parallelized and can be I/O-bound on systems with powerful CPUs. For high-traffic sites, a fast I/O system (SSD or NVMe) is recommended.

### Benchmark

A benchmark tool based on `fio` and `sysbench` is included to help you evaluate your system's performance. It requires at least **5GB** of free disk space.

```shell
docker compose -f benchmark.yaml run --rm benchmark
```

The output provides metrics for CPU, memory, and I/O performance. Use the following table to interpret your results:

| Type        | CPU-1 ops/sec | CPU-MAX ops/sec | MEMORY MiB/sec | I/O BW (MB/s) | I/O IOPS |
|-------------|---------------|-----------------|----------------|---------------|----------|
| Minimum     | 10            | 250             | 2000           | 30            | 10000    |
| Medium      | 15            | 700             | 3000           | 100           | 25000    |
| Recommended | 20            | 1000            | 4000           | 200           | 50000    |

---

## What's Next?

[![SSI Image 1](https://docs.neptunelabs.com/fsi/server?type=image&source=images/samples/ssi-1.jpg&width=170)](https://neptunelabs.github.io/fsi-image-samples/)
[![QuickZoom Image 1](https://docs.neptunelabs.com/fsi/server?type=image&source=images/samples/quick-1.jpg&width=170)](https://neptunelabs.github.io/fsi-quickzoom-samples/)
[![Zoom Image 1](https://docs.neptunelabs.com/fsi/server?type=image&source=images/samples/zoom-1.jpg&width=170)](https://neptunelabs.github.io/fsi-viewer-samples/)
[![Pages Image 1](https://docs.neptunelabs.com/fsi/server?type=image&source=images/samples/pages-1.jpg&width=170)](https://neptunelabs.github.io/fsi-pages-samples/)
[![Layers Image 1](https://docs.neptunelabs.com/fsi/server?type=image&source=images/samples/layers-1.jpg&width=170)](https://neptunelabs.github.io/fsi-layers-samples/)

Explore the full potential of FSI Server with our viewer components and single-source imaging technology. Check out our GitHub repositories for examples:
- [FSI Image Samples](https://github.com/neptunelabs/fsi-image-samples) - Single source imaging
- [FSI QuickZoom Samples](https://github.com/neptunelabs/fsi-quickzoom-samples) - Fly-out zoom
- [FSI Viewer Samples](https://github.com/neptunelabs/fsi-viewer-samples) - Zoom and Pan viewer
- [FSI Pages Samples](https://github.com/neptunelabs/fsi-pages-samples) - Interactive Brochures
- [FSI Layers Samples](https://github.com/neptunelabs/fsi-layers-samples) - Extensive configurator
- [and more samples ...](https://docs.neptunelabs.com/docs/samples/samples-intro)

For more tutorials and documentation, visit our [documentation section](https://docs.neptunelabs.com/).

## Licensing

The software can be used for evaluation purposes indefinitely, but an overlay watermark will be displayed. A free 60-day trial key without watermarks is available [here](https://www.neptunelabs.com/trial-options/trial/).

---

## Quick Reference

- **Issues:** https://github.com/neptunelabs/fsi-server-docker-v24/issues
- **Supported Architectures:** `amd64`
- **Documentation:** https://docs.neptunelabs.com/
- **GitHub:** https://github.com/neptunelabs
- **EULA:** https://www.neptunelabs.com/terms-conditions/end-user-license-agreement/

[FSIServer]: https://www.neptunelabs.com/fsi-server/
