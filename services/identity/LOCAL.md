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

## 4. 服务密钥（0015 第一条）
身份服务的全部接口都要求服务密钥，缺少或不一致一律返回 401。
- 每个调用方一把密钥，由部署环境以环境变量注入：`LELEXUE_SVC_KEY_<服务名大写>`，服务名中的 `-` 换成 `_`（如 `LELEXUE_SVC_KEY_MATH`、`LELEXUE_SVC_KEY_DATA_PLATFORM`）。密钥不入仓库、不写入代码。
- 调用方请求头：`X-Lelexue-Caller: <服务名>`、`X-Lelexue-Service-Key: <密钥>`。
- 允许的调用方由 `identity.allowed-callers` 配置，默认 `english,math,chinese,physics,chemistry`。名单内但环境中没有密钥的调用方同样被拒绝。
- 只记录拒绝次数，不记录请求内容与密钥。
- 本地启动示例：在第 3 步的命令前加 `LELEXUE_SVC_KEY_MATH='<本地自取>'`。

## 5. 停止
```
docker compose -f services/identity/docker-compose.yml down
```

## 说明
- 本地 Web 版访问不到这里的服务时，需要使用局域网地址或内网穿透，这不属于线上部署。
