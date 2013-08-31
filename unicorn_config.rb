# -*- coding: utf-8 -*-
APP_ROOT     = "#{File.dirname(__FILE__)}" unless defined?(APP_ROOT)

$unicorn_user  = `ls -l #{File.dirname(__FILE__)}/ | awk 'END{print $3}'`.chomp # slaveの実行ユーザ
$unicorn_group = `ls -l #{File.dirname(__FILE__)}/ | awk 'END{print $4}'`.chomp # slaveの実行グループ


# ---- start of config ----

# タイムアウト秒数。タイムアウトしたslaveは再起動される
$timeout = 60

# String => UNIX domain socket / FixNum => TCP socket
$listen = 5000

# ---- end of config ----

# Main Config for Unicorn
worker_processes 3
preload_app true
timeout $timeout
listen $listen

stderr_path "#{APP_ROOT}/log/unicorn.log"
stdout_path "#{APP_ROOT}/log/unicorn.log"



