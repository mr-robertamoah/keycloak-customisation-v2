-- Extra databases for our services
CREATE DATABASE auth_db;
CREATE DATABASE blog_db;
GRANT ALL PRIVILEGES ON DATABASE auth_db TO keycloak;
GRANT ALL PRIVILEGES ON DATABASE blog_db TO keycloak;