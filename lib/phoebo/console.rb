#
# Helper mixin which allows to pass different IO objects as STDOUT/STDERR.
# It creates consistent output layer for our classes.
#
# Use `include Phoebo::Console` in classes which require to write console output.
# You can override output stream for each object on class and instance level.
#
# MyClass.stdout = StringIO.new sets stream for all future instances
# MyClass.new.stdout = StringIO.new sets stream for a particular instance
#
# Default output streams are $stdout / $stderr
#
module Phoebo::Console

  attr_writer :stdout, :stderr

  def stdout
    @stdout ||= self.class.stdout
  end

  def stderr
    @stderr ||= self.class.stderr
  end

  # We want to also allow Class defaults
  module ClassMethods
    attr_writer :stdout, :stderr

    def stdout
      @stdout ||= $stdout
    end

    def stderr
      @stderr ||= $stderr
    end
  end

  # On include: also extend by ClassMethods
  def self.included(host_class)
    host_class.extend(ClassMethods)
  end
end