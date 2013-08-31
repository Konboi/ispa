class UnicornManager
  attr_reader :pid_file

  def initialize
    @pid_file = "#{Rails.root}/tmp/pids/unicorn.pid"
  end

  def master_pid
    File.read(pid_file).to_i
  end

  def worker_pids
    result = []
    ps_output = `ps w --ppid #{master_pid}`
    ps_output.split("\n").each do |line|
      chunks = line.strip.split(/\s+/, 5)
      pid, pcmd = chunks[0], chunks[4]
      next if pid !~ /\A\d+\z/ or pcmd !~ /worker/
      result << pid.to_i
    end
    result
  end

  def total_memory
    result = 0
    memory = memory_usage
    result += memory[:master][master_pid]
    memory[:worker].each do |pid, memory|
      result += memory
    end
    result
  end

  # 戻り値: {:master => {:pid => memory}, :worker => {:pid => memory, ・・・}}
  def memory_usage
    result = { :master => {master_pid => nil}, :worker => {} }
    ps_output = `ps auxw | grep unicorn_rails`
    ps_output.split("\n").each do |line|
      chunks = line.strip.split(/\s+/, 11)
      pid, pmem_rss, pcmd = chunks.values_at(1, 5, 10)
      pmem = pmem_rss.to_i * 1024
      pid = pid.to_i

      if pid == master_pid
        result[:master][pid] = pmem
      elsif worker_pids.include?(pid)
        result[:worker][pid] = pmem
      end
    end
    result
  end

  def worker_count
    worker_pids.size
  end

  def idle_worker_count
    result = 0
    before_cpu = {}
    worker_pids.each do |pid|
      before_cpu[pid] = cpu_time(pid)
    end
    sleep 1
    after_cpu = {}
    worker_pids.each do |pid|
      after_cpu[pid] = cpu_time(pid)
    end
    worker_pids.each do |pid|
      result += 1 if after_cpu[pid] - before_cpu[pid] == 0
    end
    result
  end

  def cpu_time(pid)
    usr, sys = `cat /proc/#{pid}/stat | awk '{print $14,$15 }'`.strip.split(/\s+/).collect { |i| i.to_i }
    usr + sys
  end
end
