module Prong
  module ClassMethods
    def define_hook(*args)
      args.each do |arg|
        Hooks::Define.construct(self,arg)
      end
    end

    def skip_hook(name,type,*args)
      Hooks::Skip.construct(self,name,type,args)
    end

    def skip_all_hooks(name,type,condition={})
      Hooks::SkipAll.construct(self,name,type,condition[:if])
    end
  end
end
