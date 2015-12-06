module Prong
  module Hooks
    class Skip
      def self.construct(base,name,type,list)
        self.new(base,name,type,list).handle
      end

      def initialize(base,name,type,list)
        @base = base; @name = name
        @type = type; @list = list
        @condition = (@list.pop[:if] if @list.last.kind_of?(Hash))
      end

      def handle
        if @condition
          exclude_with_condition
        else
          exclude_without_condition
        end
      end

      private
      def callbacks
        @callbacks ||= @base.send("_#{@type}_#{@name}")
      end

      def exclude_with_condition
        condition = @condition; list = @list;
        modifer = callbacks.map do |callback|
          block = proc do |c|
            list.each {|i| c.delete(i)} if instance_exec(&condition)
            next true
          end
          callback[0] << block
          callback
        end
        modify(modifer)
      end

      def exclude_without_condition
        list = @list
        modifer = callbacks.map do |callback|
          block = proc do |c|
            list.each {|i| c.delete(i)}
            next true
          end
          callback[0] << block
          callback
        end
        modify(modifer)
      end

      def modify(modifer)
        @base.send("_#{@type}_#{@name}=", modifer)
        @base.send("_#{@name}_callbacks=", Chain.new(@base, @name).prepare)
      end
    end
  end
end
