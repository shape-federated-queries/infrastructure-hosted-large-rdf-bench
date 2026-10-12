# infrastructure-hosted-large-rdf-bench

Ansible that deploys the [**LargeRDFBench Interoperable Edition**](https://zenodo.org/records/22140177) as 13 **QLever SPARQL endpoints**,
on one machine or spread over several.

Each machine downloads `rdf_datasets.zip` (5.1 GB, md5-checked), extracts only the datasets it
serves, builds their QLever indexes, and serves each one in its own Docker container at

```
http://<machine>:<port>/sparql
```

## Files

- `inventory.yml` — the machines and how to reach them (copy from `inventory.yml.example`,
  git-ignored).
- `sparql-endpoints.yml` — which dataset runs on which machine, its port, and its QLever
  memory/cache/timeout.
- `group_vars/all.yml` — global settings: Zenodo URL + md5, data directory, dataset → file mapping,
  QLever image.
- `deploy.yml` — the playbook.
- `requirements.yml` — Ansible collections needed (`community.docker`).

## 1. Prerequisites

- Ansible on your laptop, and SSH access to the machines.
- Ubuntu machines with outbound internet (Docker Hub, Zenodo) and enough disk under `~/data`
  for the zip, the extracted RDF and the indexes.

Docker is installed by the playbook.

## 2. Configure

**Machines**: `cp inventory.yml.example inventory.yml` and set each machine's address:

```yaml
qlever:
  hosts:
    node-1: { ansible_host: 192.0.2.10 }
```

**Endpoints**: in `sparql-endpoints.yml`, each dataset names its machine (`host`, an inventory
host name), a port unique across the file, and its QLever settings:

```yaml
sparql_endpoints:
  Affymetrix: { host: node-1, port: 3002, memory: 16G, cache: 4G, timeout: 1800s, index_memory: 12G }
  ChEBI:      { host: node-1, port: 3003, memory: 16G, cache: 4G, timeout: 1800s, index_memory: 12G }
```

- `memory` → `qlever-server -m`
- `cache` → `qlever-server -c`
- `timeout` → `qlever-server -s`
- `index_memory` → `qlever-index -m`

For one machine, every endpoint has `host: node-1` (the default file). For several, add `node-2`,
`node-3`, … to the inventory and point endpoints at them; each machine only downloads and serves
the datasets assigned to it. Mind the total `memory` of the endpoints sharing a machine.

## 3. Run

```bash
make ping      # all machines reachable
make deploy    # install the collections, provision, download, index and serve (re-runnable)
make health    # per container: status, restart count, OOM-killed
make stop      # remove every QLever container (data and indexes are kept)
```

Override the files with `make deploy INVENTORY=... ENDPOINTS=...`.

`make deploy` is idempotent: the download and extraction are skipped once the RDF files exist,
an index is built only if missing, and a running container is only recreated when its settings
(or the pulled image) change. Indexing the large datasets takes a while.

## Layout on each machine

```
~/data/
├── rdf_datasets.zip
└── <Dataset>/
    ├── <Dataset>.nt | .ttl     # extracted RDF
    └── <Dataset>.index.*       # QLever index
```

Containers are named `qlever-<Dataset>`.
