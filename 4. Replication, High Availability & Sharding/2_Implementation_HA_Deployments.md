A **detailed system diagram** and a **high-level production-ready deployment plan** using **Ansible** and **Kubernetes** to orchestrate a PostgreSQL HA cluster with **Patroni**, **pgpool-II**, and **PgBouncer**.

---

# 1️⃣ System Diagram: PostgreSQL HA with Patroni, pgpool-II, PgBouncer

```
                +----------------------------+
                |          Clients/App        |
                +-------------+--------------+
                              |
                         (PostgreSQL)
                              |
                +-------------v--------------+
                |          PgBouncer         |  <-- Connection pooling (lightweight)
                |   (Transaction pooling)    |
                +-------------+--------------+
                              |
                              | (SQL Routing & Load Balancing)
                              |
                +-------------v--------------+
                |          pgpool-II          |  <-- Load balancing, failover control
                +-------------+--------------+
                 /                           \
                /                             \
+---------------v-------------+   +-----------v--------------+
|   Patroni Node 1 (Primary)  |   | Patroni Node 2 (Replica)  |
|  PostgreSQL + Patroni Agent |   | PostgreSQL + Patroni Agent |
+----------------------------+   +--------------------------+
                \                             /
                 \                           /
                  +-------------------------+
                  |   Distributed Consensus  |  <-- etcd / Consul / ZooKeeper
                  +-------------------------+
```

---

# 2️⃣ Production-ready Deployment Overview

---

## A. Prerequisites

- **3 or more nodes** to run Patroni-enabled PostgreSQL for quorum and failover
- **etcd/Consul** cluster deployed externally or alongside Patroni nodes
- **pgpool-II** and **PgBouncer** deployed on dedicated nodes or as sidecars (K8s pods)
- **Load balancer or DNS** to manage client connectivity (e.g., HAProxy or Kubernetes Service)

---

## B. Ansible Playbook Outline

### Roles:

- `postgresql-patroni`: Install PostgreSQL 13+, Patroni, configure replication & DCS client
- `etcd`: Deploy and configure etcd cluster
- `pgpool`: Install and configure pgpool-II with failover scripts and monitoring
- `pgbouncer`: Setup PgBouncer with proper pooling mode and auth

### Sample tasks for `postgresql-patroni` role:

```yaml
- name: Install PostgreSQL and Patroni
  apt:
    name:
      - postgresql-13
      - patroni
      - python3-etcd
    state: present

- name: Configure Patroni (patroni.yml)
  template:
    src: patroni.yml.j2
    dest: /etc/patroni.yml
    owner: postgres
    group: postgres
    mode: "0644"

- name: Enable and start Patroni service
  systemd:
    name: patroni
    enabled: yes
    state: started
```

### Notes:

- Use `template` module for dynamic IP addressing and DCS endpoints.
- Add handlers to restart Patroni and PostgreSQL after config changes.
- Include health checks and monitoring tasks.

---

## C. Kubernetes Deployment Approach

### StatefulSet for Patroni + PostgreSQL

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: patroni
spec:
  serviceName: patroni
  replicas: 3
  selector:
    matchLabels:
      app: patroni
  template:
    metadata:
      labels:
        app: patroni
    spec:
      containers:
        - name: patroni
          image: patroni:latest
          ports:
            - containerPort: 5432
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: patroni-data
```

### Deploy etcd cluster (can be StatefulSet or external managed)

---

### Services:

- `ClusterIP` service for Patroni nodes to communicate
- `LoadBalancer` or `NodePort` for pgpool-II to expose to clients
- `PgBouncer` as a Deployment or DaemonSet for scaling horizontally

---

# 3️⃣ Additional Considerations

- **Disaster recovery**: Schedule base backups + WAL archiving with `pgBackRest` or `WAL-G`
- **Security**: Mutual TLS between Patroni nodes and DCS, enable SSL on pgpool-II and PgBouncer
- **Monitoring/Alerting**: Integrate with Prometheus + Grafana dashboards for Patroni, pgpool, PgBouncer metrics
- **Testing failover**: Automate failover tests in staging (simulate node shutdowns, network partitions)

---

Following way would be :

- **Ansible playbook setup**
- **Kubernetes YAML manifests** for Patroni, pgpool-II, and PgBouncer
- **CI/CD pipeline** for this PostgreSQL HA stack
- **scripts** for health checks and failover automation
