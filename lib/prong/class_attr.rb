module Prong
  module ClassAttr
    def class_attr(*args)
      args.each do |arg|
        define_singleton_method(arg) { [] }
        define_singleton_method("#{arg}=") { |param| define_singleton_method(arg) { param } }
      end
    end
  end
end
