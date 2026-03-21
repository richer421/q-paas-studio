# 核心数据模型

系统核心实体及其关系。新增实体时在此注册。

## BaseModel（通用基础字段）

| 字段 | 类型 | 说明 |
|------|------|------|
| ID | int64 | 主键，自增 |
| CreatedAt | time.Time | 创建时间，自动填充 |
| UpdatedAt | time.Time | 更新时间，自动填充 |

## 实体清单

### DeployPlan（部署计划）

| 字段 | 类型 | 说明 |
|------|------|------|
| ID | int64 | 主键 |
| Name | string | 部署计划名称，业务单元内唯一 |
| Description | string | 部署计划说明 |
| BusinessUnitID | int64 | 所属业务单元 |
| CIConfigID | int64 | 关联的 CI 配置 |
| CDConfigID | int64 | 关联的 CD 配置 |
| InstanceOAMID | int64 | 关联的实例配置 |
| CreatedAt | time.Time | 创建时间 |
| UpdatedAt | time.Time | 更新时间 |

说明：
- DeployPlan 是业务单元下的组合配置实体，用于把构建、部署、实例运行配置绑定为一个可执行配置包。
- DeployPlan 的列表/详情展示会额外聚合实例环境、CI/CD/实例名称等展示字段。
- 当前 LastStatus / LastTime 仍是前端展示占位信息，尚未沉淀为独立发布历史模型。
