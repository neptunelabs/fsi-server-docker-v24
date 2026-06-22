# FSI Server Container Setup (v24.x)

[![FSI Server Logo](http://fsi-site.neptunelabs.com/fsi/server?type=image&source=images%2Ffsi-logos%2Ffsi_server.png&width=250&height=86&format=png)][FSIServer]

<p align="center">
  <a href="#getting-started"><strong>Getting Started</strong></a> ·
  <a href="#configuration"><strong>Configuration</strong></a> ·
  <a href="#advanced-topics"><strong>Advanced Topics</strong></a> ·
  <a href="#licensing"><strong>Licensing</strong></a> ·
  <a href="#quick-reference"><strong>Quick Reference</strong></a>
</p>

---

## What is [FSI Server][FSIServer]?

FSI Server dynamically generates images in various formats, sizes, and qualities in real-time.
Upload a single high-resolution source image, and FSI Server will deliver variations on-demand via HTTP queries.
This eliminates not only manual image preparation, but also any pre-calculation of image sizes, qualities, and formats. No variants need to be calculated or kept on hand.
FSI Server also includes a suite of viewer components for easy integration into websites and web applications.

## Getting Started

### Requirements

- **Architecture:** x86-64
- **RAM:** A minimum of 4 GB is recommended, with at least 2 GB available per CPU thread. 16 GB is sufficient for up to 1 million images; for large production environments, up to 64 GB is recommended. For technical reasons (G1 Garbage Collector), any more than this is not advisable.
- **Docker:** and Docker Compose V2 or higher.

### How to Use This Repository

**Copy the '.env.example' file to '.env'** and customize the variables to suit your needs.
However, if you're using the default settings and just testing, you don't need to make any changes.

We recommend changing the value for `SERVER_DOMAINS` to match one of your domains and then accessing
the web interface via that domain once the server has started.

If you wish to run FSI Server directly behind an HTTP reverse proxy,
you can disable the included Caddy proxy by removing the value `proxy` from the `COMPOSE_PROFILES` variable.

If this value is not configured, the server's interface can be accessed via https://localhost/ with a self-signed certificate.

You can find out more about configuration below.

### Starting Server

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

### Upgrade

For users upgrading from V22.x, we recommend that you do not transfer the .env file,
but instead adapt the one provided here accordingly.
Some variable names have changed.
The `conf` directory no longer contains any configuration files for `nginx`,
as this has been removed in favour of `caddy`.
Apache Solr has been updated to version 10, which is not compatible with the files from Solr 6.

### Web Interface

Once the containers are running, you can access the FSI Server web interface. By default, it's available at:

https://localhost/

---

## Configuration

### `compose.yaml` and `.env`

The `compose.yaml` file orchestrates the necessary services. Service activation is managed via Docker Compose profiles in the `.env` file. The default setup includes:
- [FSI Server](https://www.neptunelabs.com/fsi-server/) for image generation.
- [Caddy](https://caddyserver.com/) for automatic HTTPS and reverse proxying.
- [Apache Solr](https://solr.apache.org/) for search.
- [lsyncd](https://github.com/lsyncd/lsyncd) for optional mirror synchronization.

The primary configuration is managed through the `.env` file. Adjust the paths and settings to match your environment.

> __Important: The `.env` file format is not compatible with container setup version 22. Transfer values manually, as several variable names have changed.__

| VARIABLE                | DESCRIPTION                                                               |
|-------------------------|---------------------------------------------------------------------------|
| `COMPOSE_PROFILES`      | Comma-separated list of services to enable (`proxy`, `search`, `mirror`). |
| `SERVER_DOMAINS`        | Your public domain(s). Caddy will manage SSL for these.                   |
| `FSI_SERVER_IMAGE_NAME` | The FSI Server container repository                                       |
| `FSI_SERVER_IMAGE_TAG`  | The FSI Server version to use. (e.g. 24.07)                               |
| `FSI_CONFIG_PATH`       | Filesystem path for FSI Server configuration.                             |
| `CONNECTOR_PATH`        | Filesystem path for your source images and static assets.                 |
| `STORAGE_PATH`          | Filesystem path for optimized, real-time-ready images.                    |
| `OVERLAY_PATH`          | Configuration folder for FSI Viewer settings.                             |
| `SOLR_SERVER_URI`       | HTTP path to the Apache Solr server.                                      |
| `LOG_PATH`              | Central directory for all log files.                                      |
| `LOG_FSI_LEVEL`         | Log output verbosity for the FSI Server.                                  |
| `FSI_MEM_LIMIT`         | Maximum memory limit for the FSI Server container (e.g., 4G).             |
| `SOLR_MEM_LIMIT`        | Maximum memory limit for the Apache Solr container (e.g., 2G).             |
| `MIRROR_HOSTNAME`       | Domain name or IP of the mirror server.                                   |
| `MIRROR_SSH_PORT`       | The SSH port of the mirror server, usually 22.                            |
| `MIRROR_SYNC_KEY`       | Path to the lsyncd private key for synchronization.                       |

### Directory Structure

- **`builder/`**: Contains Dockerfiles for building the lsync and benchmark containers. Modifications are typically not needed.
- **`conf/caddy/`**: Holds the `Caddyfile` for configuring the reverse proxy. Caddy automatically handles certificate management.
- **`conf/fsi-server/`**: Contains all FSI Server settings. The container requires write access to this directory.
- **`conf/lsyncd/`**: Configuration for the lsyncd container, used for mirror server synchronization.
- **`conf/solr/`**: Configuration for the Apache Solr container. No adjustments are required here.
- **`connectors/`**: Default location for your source images and static files. This path is configurable via the `CONNECTOR_PATH` variable.
- **`fsi-data/logs/`**: *(created on start)* Central location for all service logs.
- **`fsi-data/overlay/`**: *(created on start)* Stores presets and skins for the FSI Viewer.
- **`fsi-data/storage/`**: *(created on start)* Stores optimized versions of your assets. This directory is mandatory for persistence.

### Where to put my images?

For testing, you can place your images in `connectors/images` and static files in `connectors/statics`.
For production, store your assets in a location suitable for your backup and synchronization strategy.
Then, update or create new connectors in `conf/fsi-server/connectors` to map to your asset locations.

### Kubernetes

FSI Server can also be deployed in a Kubernetes environment. Ensure that the asset and storage volumes are connected as efficiently as possible, potentially using local storage nodes for performance. If using S3-based storage (e.g., via `s3fs-fuse` or `mountpoint-s3`), we recommend running benchmarks before going live.

---

## Running in production

For productive operation with millions of images, a few settings should be changed.
All production data should reside outside the repository.
It should be configured so that the loss of the repository and the Docker images does not pose a problem.

### The `conf` directory should be moved to a different location

To ensure a quick restart in case of errors, updates, repository changes, and other modifications,
the `conf` directory should be moved.
This can be done by changing the path of `FSI_CONFIG_PATH` in the `.env` file to an absolute directory
outside the repository, e.g., `/data/conf/fsi-server`.

### Make sure the assets (images) are located outside the repository

Production images and assets can be easily addressed via the `CONNECTOR_PATH` variable.
This variable is mounted to `/connectors` within the container in the `compose.yaml` file.

When you create new connectors in `conf/fsi-server/connectors`,
this path effectively serves as the basis.
For example, you set the path to `/data/assets` and have two directories within it,
each pointing to a connector: `brands` and `logos`.
In the connectors, which you can name as you wish,
the `origin.location` path will then be `/connectors/brands` and `/connectors/logos`,
respectively.

### The storage (the internal image cache) should be outsourced

The storage should definitely be located outside the repository.
Ideally, `STORAGE_PATH` should be set to an absolute, block-oriented device.

> Under no circumstances should the storage be set to a network device.

The speed of FSI Server is largely determined by the I/O performance of the storage.
If you are unsure, run a benchmark (see below).

### Adjusting `max_user_watches` under Linux

FSI Server monitors source directories using the Linux inotify subsystem.

By default, the maximum number of files and directories that can be monitored is limited.

You should definitely adjust this value if you have more than 8000 directories.

You can determine the current value as follows:

```shell
cat /proc/sys/fs/inotify/max_user_watches

```

Increase the value by adding or modifying the following line in the `/etc/sysctl.conf` file, for example:

```shell
fs.inotify.max_user_watches=524288
```

Adjust the value according to the number of source directories.


## Advanced Topics

### Synchronization with `lsyncd`

For high-availability setups, enable the `mirror` profile in `COMPOSE_PROFILES`. This service uses **lsyncd** to synchronize assets and configurations.

**Setup:**
1.  Ensure the target server has `ssh` and `rsync` installed.
2.  Create and copy an SSH key for authentication.
    ```shell
    ssh-keygen -t ed25519 -q -N "" -o -C "fsi-sync-key@$(hostname)" -f ./conf/lsyncd/sync.key
    ssh-copy-id -i ./conf/lsyncd/sync.key user@fsi-secondary.domain.tld
    ```
3.  Update `MIRROR_HOSTNAME` and `MIRROR_SYNC_KEY` in your `.env` file.
4.  Customize synchronization paths in `conf/lsyncd/lsyncd.conf.lua` if your directory structure differs.
5.  Restart the lsyncd container: `docker compose restart lsyncd` and check the logs: `docker compose logs -f lsyncd`.

> **Important:** Do **not** synchronize the `storage` directory. Each server should build its own storage to avoid cache inconsistencies.

### Backup

A solid backup strategy is crucial.
- **Essential:** Back up the `conf/fsi-server` directory.
- **Recommended:** Also back up `$OVERLAY_PATH` and `$STORAGE_PATH/metadata`.
- **Optional:** The search index (`solr-core`) does not need to be backed up.

### Caddy and SSL/TLS Certificates

The included [Caddy](https://caddyserver.com/) service provides a reverse proxy and automatic HTTPS for your FSI Server instance.

- **Automatic SSL:** Caddy will automatically obtain and renew SSL certificates from Let's Encrypt for the domains you specify in the `SERVER_DOMAINS` variable in the `.env` file.
- **Configuration:** The proxy behavior is defined in `conf/caddy/Caddyfile`. For most use cases, you won't need to modify this file.
- **Local Development:** For `localhost`, Caddy generates a self-signed certificate, which may cause browser warnings.

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
| Recommended | \>20          | \>1000          | \>4000         | \>200         | \>50000  |

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
