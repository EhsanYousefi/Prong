module Prong
  module Hooks
    class SkipAll
      def self.construct(base,name,type,condition)
        self.new(base,name,type,condition).handle
      end

      def initialize(base,name,type,condition)
        @base = base; @name = name
        @type = type; @condition = condition
      end

      def handle
        if @condition
          exclude_all_with_condition
        else
          exclude_all_without_condition
        end
      end

      private
      def callbacks
        @callbacks ||= @base.send("_#{@type}_#{@name}")
      end

      def exclude_all_without_condition
        modifier = callbacks.map do |callback|
          block = proc do |c|
            c.clear
            next true
          end
          callback[0] << block
          callback
        end
        modify(modifier)
      end

      def exclude_all_with_condition
        condition = @condition
        modifier = callbacks.map do |callback|
          block = proc do |c|
            c.clear if instance_exec(&condition)
            next true
          end
          callback[0] << block
          callback
        end
        modify(modifier)
      end

      def modify(modifier)
        @base.send("_#{@type}_#{@name}=", modifier)
        @base.send("_#{@name}_callbacks=", Chain.new(@base, @name).prepare)
      end
    end
  end
end
