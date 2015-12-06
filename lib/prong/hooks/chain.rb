module Prong
  module Hooks
    class Chain
      def initialize(base, name)
        @base = base
        @name = name
      end

      def prepare
        all; before; after; around; return self
      end

      def compile(block, type)
        callbacks = instance_variable_get("@#{type}")
        callbacks[0][callbacks[1]] = [block,[]]
        return callbacks[0]
      end

      private
      def all
        @all = [([] + get_before + get_around + ['_***_'] + get_around + get_after)]
        @all << @all[0].index('_***_')
      end

      def before
        @before = [([] + get_before + ['_***_'])]
        @before << @before[0].index('_***_')
      end

      def after
        @after = [(['_***_'] + get_after)]
        @after << @after[0].index('_***_')
      end

      def around
        @around = [(get_around + ['_***_'] + get_around)]
        @around << @around[0].index('_***_')
      end

      def get_before
        @get_before ||= deep_dup(@base.send("_before_#{@name}"))
      end

      def get_around
        @get_around ||= deep_dup(@base.send("_around_#{@name}"))
      end

      def get_after
        @get_after ||= deep_dup(@base.send("_after_#{@name}"))
      end

      def deep_dup(array)
        array.map do |it|
          if it.class == Array
            # recursive method call instead of while loop
            next deep_dup(it.dup)
          else
            next it
          end
        end
      end
    end
  end
end
