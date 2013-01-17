module DoubanFM
  class DummyLogger
    def log(message); end
  end

  class ConsoleLogger
    def log(message)
      puts message
    end
  end
end
