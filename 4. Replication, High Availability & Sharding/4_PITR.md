# **PostgreSQL Point-In-Time Recovery (PITR)**

---

## 🔍 What is PITR?

**Point-In-Time Recovery** allows restoring a PostgreSQL database to a specific moment—useful for recovering from:

- Human errors (e.g., accidental deletes)
- Application bugs
- Data corruption or ransomware attacks

PITR uses:

1. A **base backup** (via `pg_basebackup` or filesystem snapshot)
2. A continuous stream of **WAL (Write-Ahead Log)** files

---

## ⚙️ How PITR Works (Conceptually)

1. PostgreSQL writes all changes to WAL before committing to disk (write-ahead logging).
2. A **base backup** is taken (snapshot of data directory).
3. WAL files are continuously archived.
4. During recovery, the base backup is restored.
5. Then WAL files are replayed **until the specified timestamp**.

---

## 🏦 Real-World Banking Use Case

In a banking system (e.g., `banking_db`), a system bug might transfer ₹10,000 from 1000 accounts erroneously. If noticed 15 minutes later:

- You can recover the DB to **exactly before** that transaction.

---

## ✅ Prerequisites for PITR (Applied to Your Setup)

### 1. **Enable WAL Archiving**

```conf
archive_mode = on
archive_command = 'test ! -f /wal_archive/%f && cp %p /wal_archive/%f'
wal_level = replica
max_wal_senders = 5
wal_keep_size = 1GB
```

💡 `archive_command` must **not fail silently**; monitor it via logs.

### 2. **Take Base Backups Regularly**

```bash
pg_basebackup -D /backups/banking_db_$(date +%F_%T) -F tar -z -P -X fetch
```

- `-X fetch`: fetch WAL after backup finishes (ensure consistency)
- `-F tar`: creates tar archive for easy storage/transfer
- Automate with `cron` or systemd timer

### 3. **Restore in Disaster Case**

```bash
tar -xzf 2025-05-17_13:00:00.tar.gz -C $PGDATA
```

Create `recovery.signal` to indicate PostgreSQL must enter recovery mode.

Then define target:

```conf
restore_command = 'cp /wal_archive/%f %p'
recovery_target_time = '2025-05-17 12:45:00'
```

---

## 🚦 Recovery Targets Available

| Target Type            | Usage Example                                                                |
| ---------------------- | ---------------------------------------------------------------------------- |
| `recovery_target_time` | Exact timestamp like `'2025-05-17 12:45:00'`                                 |
| `recovery_target_name` | A named restore point via `SELECT pg_create_restore_point('before_delete');` |
| `recovery_target_xid`  | Transaction ID (less commonly used)                                          |

💡 In banking, **named restore points** are highly valuable during big batch jobs.

---

## 🛡️ Best Practices

- **Use dedicated volume** for WAL archive
- **Encrypt** backups (e.g., `gpg`)
- **Replicate PITR flow in staging** monthly
- **Store base backups offsite**
- **Retain enough WAL files** to span between backups (or PITR won’t work)

---

## 🧪 Testing PITR (Every Release Cycle)

1. Backup production-like data
2. Simulate disaster
3. Perform PITR
4. Validate:

   - Transactions rolled back
   - No corruption
   - Indexes, constraints remain intact

---

## 📈 Scaling PITR for Large Banking Systems

- Use **pgBackRest** or **Barman** for automation, compression, integrity checks
- Store WALs in **cloud buckets (e.g., S3/MinIO)** with versioning
- Use **LVM/ZFS snapshots** for base backups in large setups
- Parallelize recovery with `restore_command` speed tuning

---

Suggestion:

1. Add support for `pgBackRest` (advanced backup tool)?
2. Add recovery using a named restore point?
3. Generate a cron-based backup plan?
