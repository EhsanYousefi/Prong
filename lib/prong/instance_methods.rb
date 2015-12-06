module Prong
  module InstanceMethods
    def run_hooks(name,type = 'all', return_all = false, &block)
      return Hooks::Executer::Falsey.without_return_all(self,name,type,&block) unless return_all
      return Hooks::Executer::Falsey.with_return_all(self,name,type,&block)
    end

    def run_hooks!(name,type = 'all', return_all = false, &block)
      return Hooks::Executer.without_return_all(self,name,type,&block) unless return_all
      return Hooks::Executer.with_return_all(self,name,type,&block)
    end
  end
end
