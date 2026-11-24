# 身份服务本地运行（方案 A）

身份服务与 MySQL 只在本地运行，不部署到线上。

## 1. 启动数据库
```
docker compose -f services/identity/docker-compose.yml up -d
```
- 开发库：`localhost:3306`，库 `identity`，用户 `identity` / `identity`。
- 测试库：`localhost:3307`，库 `identity_test`，用户 `identity_test` / `identity_test`。

## 2. 运行测试
```
cd services/identity
IDENTITY_TEST_DB_URL='jdbc:mysql://localhost:3307/identity_test?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC' mvn -B test
```
测试默认连 `localhost:3306/identity_test`；使用上面的 compose 时需用 3307 端口覆盖。

## 3. 启动服务
```
cd services/identity
IDENTITY_DB_URL='jdbc:mysql://localhost:3306/identity?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC' mvn -B spring-boot:run
```
默认端口 8081（`IDENTITY_PORT` 可改）。

## 4. 停止
```
docker compose -f services/identity/docker-compose.yml down
```

## 说明
- 本地 Web 版访问不到这里的服务时，需要使用局域网地址或内网穿透，这不属于线上部署。
