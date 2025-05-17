# Hibernate

However, for Hibernate to work properly, you **do need supporting libraries and a few configurations**. Here's what you need:

---

### ✅ Required Components to Support Hibernate

| Component                               | Purpose                                       |
| --------------------------------------- | --------------------------------------------- |
| **Hibernate Core**                      | The main ORM library.                         |
| **JDBC Driver (e.g., PostgreSQL)**      | To connect Hibernate to the database.         |
| **JPA API**                             | Optional but often used with Hibernate.       |
| **Logging (SLF4J, Logback/Log4j)**      | Hibernate logs all SQL and internal behavior. |
| **Connection Pooling (HikariCP, C3P0)** | Efficient database connections (optional).    |

---

### 🧰 Maven Dependencies Example (Hibernate + PostgreSQL)

```xml
<dependencies>
    <!-- Hibernate Core -->
    <dependency>
        <groupId>org.hibernate</groupId>
        <artifactId>hibernate-core</artifactId>
        <version>6.3.1.Final</version>
    </dependency>

    <!-- PostgreSQL JDBC Driver -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <version>42.7.1</version>
    </dependency>

    <!-- JPA API (Optional, useful with annotations) -->
    <dependency>
        <groupId>jakarta.persistence</groupId>
        <artifactId>jakarta.persistence-api</artifactId>
        <version>3.1.0</version>
    </dependency>

    <!-- Logging for Hibernate -->
    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-api</artifactId>
        <version>2.0.9</version>
    </dependency>
    <dependency>
        <groupId>ch.qos.logback</groupId>
        <artifactId>logback-classic</artifactId>
        <version>1.4.11</version>
    </dependency>
</dependencies>
```

---

### ⚙️ Configuration Required (hibernate.cfg.xml or application.properties)

You must also configure Hibernate via XML or properties file to define:

- database connection URL
- username/password
- dialect
- entity classes

Example (in `hibernate.cfg.xml`):

```xml
<hibernate-configuration>
  <session-factory>
    <property name="hibernate.connection.driver_class">org.postgresql.Driver</property>
    <property name="hibernate.connection.url">jdbc:postgresql://localhost:5432/your_db</property>
    <property name="hibernate.connection.username">your_user</property>
    <property name="hibernate.connection.password">your_password</property>
    <property name="hibernate.dialect">org.hibernate.dialect.PostgreSQLDialect</property>
    <property name="hibernate.hbm2ddl.auto">update</property>
    <property name="hibernate.show_sql">true</property>
  </session-factory>
</hibernate-configuration>
```

---

### 🟢 Summary

You **don’t need to install anything manually**. Once you:

- add the right Maven dependencies,
- configure the connection properly,
- and annotate your entity classes,
