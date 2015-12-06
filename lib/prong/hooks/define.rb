require_relative 'chain'
module Prong
  module Hooks
    class Define
      def self.construct(base,arg)
        self.new(base,arg).handle
      end

      def initialize(base,name)
        @base = base
        @name = name
      end

      def handle
        callback_attrs
        define_callbacks_chain
        define_callbacks
      end

      private
      def callback_attrs
        @callback_attrs ||= @base.class_attr("_before_#{@name}", "_around_#{@name}", "_after_#{@name}")
      end

      def define_callbacks_chain
        @base.class_attr("_#{@name}_callbacks")
        @base.send("_#{@name}_callbacks=", Chain.new(@base, @name).prepare)
      end

      def define_callbacks
        callback_attrs.each do |attribute|
          name = @name
          @base.class_eval do
            define_singleton_method(attribute[1..-1]) do |*args, &block|
              condition = (args.pop if args.last.kind_of?(Hash)) || {}
              args << block if block
              self.send("#{attribute}=", self.send("#{attribute}") << [[condition[:if]].compact, args])
              self.send("_#{name}_callbacks=", Chain.new(self, name).prepare)
            end
          end
        end
      end
    end
  end
end
