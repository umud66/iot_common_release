# 中文注释：数据库镜像只在官方 postgres 基础上内置初始化 migrations。
FROM postgres:16-alpine

COPY migrations/*.sql /docker-entrypoint-initdb.d/
