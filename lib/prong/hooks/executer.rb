module Prong
  module Hooks
    module Executer
      module Falsey
        def self.with_return_all(obj,name,type,&block)
          return_block = nil
          return_collection = []
          closure = Proc.new { return_block ||= block.call if block }
          callbacks = obj.class.send("_#{name}_callbacks")
          callbacks.compile([closure],type).each do |callback|
            callback[0].each { |b| next callback[1].clear unless obj.instance_exec(callback[1], &b) }
            return_collection << callback[1].map do |i|
              case i
                when Symbol
                  if (o = obj.send(i)) == false
                    return false
                  else
                    next o
                  end
                when Proc
                  if (o = obj.instance_exec(&i)) == false
                    return false
                  else
                    next o
                  end
              end
            end
          end
          return [return_collection.flatten].push([return_block||true].flatten)
        end

        def self.without_return_all(obj,name,type,&block)
          return_block = nil
          closure = Proc.new { return_block ||= block.call if block }
          callbacks = obj.class.send("_#{name}_callbacks")
          callbacks.compile([closure],type).each do |callback|
            callback[0].each { |b| next callback[1].clear unless obj.instance_exec(callback[1], &b) }
            callback[1].each do |i|
              case i
                when Symbol
                  if obj.send(i) == false
                    return false
                  else
                    next
                  end
                when Proc
                  if obj.instance_exec(&i) == false
                    return false
                  else
                    next
                  end
              end
            end
          end
          return return_block || true
        end
      end

      def self.with_return_all(obj,name,type,&block)
        return_block = nil
        return_collection = []
        closure = Proc.new { return_block ||= block.call if block }
        callbacks = obj.class.send("_#{name}_callbacks")
        callbacks.compile([closure],type).each do |callback|
          callback[0].each { |b| next callback[1].clear unless obj.instance_exec(callback[1], &b) }
          return_collection << callback[1].map { |i| case i when Symbol then next obj.send(i) when Proc then next obj.instance_exec(&i) end }
        end
        return [return_collection.flatten].push([return_block||true].flatten)
      end

      def self.without_return_all(obj,name,type,&block)
        return_block = nil
        closure = Proc.new { return_block ||= block.call if block }
        callbacks = obj.class.send("_#{name}_callbacks")
        callbacks.compile([closure],type).each do |callback|
          callback[0].each { |b| next callback[1].clear unless obj.instance_exec(callback[1], &b) }
          callback[1].each { |i| case i when Symbol then next obj.send(i) when Proc then next obj.instance_exec(&i) end }
        end
        return return_block || true
      end
    end
  end
end
