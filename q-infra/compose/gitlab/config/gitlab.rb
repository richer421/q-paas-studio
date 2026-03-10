# GitLab Omnibus 配置
# https://docs.gitlab.com/omnibus/settings/configuration.html

external_url ENV['GITLAB_EXTERNAL_URL'] || 'http://localhost:8929'

# 监听端口（匹配 external_url）
nginx['listen_port'] = 8929

# 管理员初始密码
gitlab_rails['initial_root_password'] = ENV['GITLAB_ROOT_PASSWORD'] || 'changeme123'

# 禁用不需要的组件以减少资源占用
prometheus_monitoring['enable'] = false
grafana['enable'] = false

# Puma 性能调优（降低内存占用）
puma['worker_processes'] = 2

# Sidekiq 并发
sidekiq['max_concurrency'] = 10

# SSH 设置
gitlab_rails['gitlab_shell_ssh_port'] = ENV['GITLAB_SSH_PORT']&.to_i || 2224
