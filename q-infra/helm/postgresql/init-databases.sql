-- PostgreSQL 初始化脚本
-- 为 Harbor 和 GitLab 创建数据库

-- Harbor 数据库
CREATE DATABASE harbor_core;
CREATE DATABASE harbor_notary_server;
CREATE DATABASE harbor_notary_signer;

-- GitLab 数据库
CREATE DATABASE gitlabhq_production;

-- 授权 (如果需要单独用户)
-- GRANT ALL PRIVILEGES ON DATABASE harbor_core TO postgres;
-- GRANT ALL PRIVILEGES ON DATABASE harbor_notary_server TO postgres;
-- GRANT ALL PRIVILEGES ON DATABASE harbor_notary_signer TO postgres;
-- GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production TO postgres;