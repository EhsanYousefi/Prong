require "prong/version"
require "prong/hooks/define"
require "prong/hooks/skip"
require "prong/hooks/skip_all"
require "prong/hooks/executer"
require "prong/class_methods"
require "prong/instance_methods"
require "prong/class_attr"

module Prong
  def self.included(host)
    host.extend(ClassAttr)
    host.extend(ClassMethods)
    host.include(InstanceMethods)
  end
end
