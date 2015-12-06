require 'spec_helper'
require 'pry'
describe Prong do

  describe 'Define hooks' do

    it 'should define multiple hooks' do

      klass = Class.new do
        include Prong
        define_hook :save, :update
      end

      expect(klass.methods.grep(/_save/).count).to eql 11
      expect(klass.methods.grep(/_update/).count).to eql 11

    end

    it 'should define hooks on multiple calls' do

      klass = Class.new do
        include Prong
        define_hook :save
        define_hook :update
      end

      expect(klass.methods.grep(/_save/).count).to eql 11
      expect(klass.methods.grep(/_update/).count).to eql 11

    end

  end

  describe 'Set hooks' do

    it 'should set `save` hooks' do

      klass = Class.new do
        include Prong
        define_hook :save
        before_save :validate
        around_save :log
        after_save  :notify
      end

      expect(klass._before_save.inspect.include?('validate')).to be true
      expect(klass._before_save.inspect.include?('log')).to be false
      expect(klass._before_save.inspect.include?('notify')).to be false

      expect(klass._around_save.inspect.include?('log')).to be true
      expect(klass._around_save.inspect.include?('validate')).to be false
      expect(klass._around_save.inspect.include?('notify')).to be false

      expect(klass._after_save.inspect.include?('notify')).to be true
      expect(klass._after_save.inspect.include?('validate')).to be false
      expect(klass._after_save.inspect.include?('log')).to be false

    end

    it 'should set multiple `save` hooks' do

      klass = Class.new do
        include Prong
        define_hook :save
        before_save :validate_name, :validate_gender
        around_save :log_exec_time, :stdout
        after_save  :notify_via_email, :notify_via_sms
      end

      expect(klass._before_save.inspect.include?('validate_name')).to be true
      expect(klass._before_save.inspect.include?('validate_gender')).to be true

      expect(klass._around_save.inspect.include?('log_exec_time')).to be true
      expect(klass._around_save.inspect.include?('stdout')).to be true

      expect(klass._after_save.inspect.include?('notify_via_email')).to be true
      expect(klass._after_save.inspect.include?('notify_via_sms')).to be true

    end

    it 'should set `before_update` hook alongside `save` hooks' do

      klass = Class.new do
        include Prong
        define_hook :save, :update
        before_save :validate_name, :validate_gender
        around_save :log_exec_time, :stdout
        after_save  :notify_via_email, :notify_via_sms
        before_update :validate_email
      end

      expect(klass._before_update.inspect.include?('validate_email')).to be true

      expect(klass._before_save.inspect.include?('validate_name')).to be true
      expect(klass._before_save.inspect.include?('validate_gender')).to be true

      expect(klass._around_save.inspect.include?('log_exec_time')).to be true
      expect(klass._around_save.inspect.include?('stdout')).to be true

      expect(klass._after_save.inspect.include?('notify_via_email')).to be true
      expect(klass._after_save.inspect.include?('notify_via_sms')).to be true

    end

  end

  describe 'Run hooks' do

    context 'Before Save' do
      it 'should only run `before_save` hooks' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          after_save :notify
          around_save :log
          def notify; order << :notify; end
          def log; order << :log; end
          def validate
            order << :validate
          end
          def save
            run_hooks!(:save, :before) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :save
        expect(object.order[2]).to be nil

      end
    end

    context 'After Save' do
      it 'should only run `after_save` hooks' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          after_save :notify
          around_save :log
          def notify; order << :notify; end
          def log; order << :log; end
          def validate
            order << :validate
          end
          def save
            run_hooks!(:save, :after) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :save
        expect(object.order[1]).to be :notify
        expect(object.order[2]).to be nil

      end
    end

    context 'Around Save' do
      it 'should only run `around_save` hooks' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          after_save :notify
          around_save :log
          def notify; order << :notify; end
          def log; order << :log; end
          def validate
            order << :validate
          end
          def save
            run_hooks!(:save, :around) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :log
        expect(object.order[1]).to be :save
        expect(object.order[2]).to be :log
        expect(object.order[3]).to be nil

      end
    end

    it 'should run `before_save` hook in correct order' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        def validate
          order << :validate
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :save

    end

    it 'should return from callback' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :authorize
        around_save :log
        after_save :notify
        def authorize
          order << :authorize
          raise 'Unauthorized!'
        end
        def log
          order << :log
        end
        def notify
          order << :notify
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      expect{object.save}.to raise_error(RuntimeError)

      expect(object.order[0]).to be :authorize
      expect(object.order[1]).to be nil

    end

    it 'should run multiple kind of hooks' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save, :save_2
        before_save :validate
        before_save_2 :validate_2
        def validate; order << :validate; end
        def validate_2; order << :validate_2; end
        def save
          run_hooks!(:save_2) do
            run_hooks!(:save) do
              order << :save
            end
          end
        end
      end

      object = klass.new
      object.order = []
      expect(object.save).to eql [:validate_2, :validate, :save]

      expect(object.order[0]).to be :validate_2
      expect(object.order[1]).to be :validate
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be nil

    end

    it 'should run `around_save` hook in correct order' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        around_save :log
        def log
          order << :log
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :log
      expect(object.order[1]).to be :save
      expect(object.order[2]).to be :log

    end

    it 'should run `after_save` hook in correct order' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        after_save :notify
        def notify
          order << :notify
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :save
      expect(object.order[1]).to be :notify

    end

    it 'should run `*_save` hooks in correct order' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        around_save :log
        after_save  :notify
        def validate
          order << :validate
        end
        def log
          order << :log
        end
        def notify
          order << :notify
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :log
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be :log
      expect(object.order[4]).to be :notify
      expect(object.order[5]).to be nil

    end

    it 'should run multiple `*_save` hooks in correct order' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate, :validate_2
        around_save :log, :log_2
        after_save  :notify, :notify_2
        def validate
          order << :validate
        end
        def validate_2
          order << :validate_2
        end
        def log
          order << :log
        end
        def log_2
          order << :log_2
        end
        def notify
          order << :notify
        end
        def notify_2
          order << :notify_2
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :validate_2
      expect(object.order[2]).to be :log
      expect(object.order[3]).to be :log_2
      expect(object.order[4]).to be :save
      expect(object.order[5]).to be :log
      expect(object.order[6]).to be :log_2
      expect(object.order[7]).to be :notify
      expect(object.order[8]).to be :notify_2
      expect(object.order[9]).to be nil

    end

    it 'should run proc objects alongside methods' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate, proc { order << :block }, :validate_email
        def validate
          order << :validate
        end
        def validate_email
          order << :validate_email
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :block
      expect(object.order[2]).to be :validate_email
      expect(object.order[3]).to be :save
      expect(object.order[4]).to be nil

    end

    it 'should run proc(lambda) objects alongside methods' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate, -> { order << :block }, :validate_email
        def validate
          order << :validate
        end
        def validate_email
          order << :validate_email
        end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :block
      expect(object.order[2]).to be :validate_email
      expect(object.order[3]).to be :save
      expect(object.order[4]).to be nil

    end

    it 'should run hooks and return `save` method value in the end' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        around_save :log
        after_save :notify

        def validate; order << :validate; "validate"; end
        def log; order << :log; "log"; end
        def notify; order << :notify; "notify"; end

        def save
          run_hooks!(:save) do
            order << :save
            "save"
          end
        end
      end

      object = klass.new
      object.order = []
      expect(object.save).to eql "save"

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :log
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be :log
      expect(object.order[4]).to be :notify
      expect(object.order[5]).to be nil

    end

    context 'Conditional hooks' do

      it 'should not run hooks in expression if `if clause` returned `false`' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate_email, -> { order << :block }, if: proc { run? }
          before_save :validate
          def run?
            false
          end
          def validate
            order << :validate
          end
          def validate_email
            order << :validate_email
          end
          def save
            run_hooks!(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :save
        expect(object.order[2]).to be nil

      end

      it 'should run hooks in expression if `if clause` returned `true`' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          before_save :validate_email, -> { order << :block }, if: proc { run? }
          def run?
            true
          end
          def validate
            order << :validate
          end
          def validate_email
            order << :validate_email
          end
          def save
            run_hooks!(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :validate_email
        expect(object.order[2]).to be :block
        expect(object.order[3]).to be :save
        expect(object.order[4]).to be nil

      end
    end

    it 'should run hooks(return true) without closure' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        around_save :log
        after_save :notify
        def validate; order << :validate; end
        def log; order << :log; end
        def notify; order << :notify; end
        def save
          run_hooks!(:save)
        end
      end

      object = klass.new
      object.order = []
      expect(object.save).to be true

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :log
      expect(object.order[2]).to be :log
      expect(object.order[3]).to be :notify
      expect(object.order[4]).to be nil

    end

    context 'Return all hooks' do
      it 'should return all hooks in collection + block which evaluated in run_hook method' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate_2, if: proc { run? }
          before_save :validate, -> { order << :validate_block; :validate_block}
          around_save :log, -> { order << :log_block; :log_block }
          after_save :notify, -> { order << :notify_block; :notify_block }
          def run?; false; end
          def validate; order << :validate; :validate; end
          def log; order << :log; :log; end
          def notify; order << :notify; :notify; end
          def save
            run_hooks!(:save, :all, :return_all) do
              order << :save; :save
            end
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to eql [[:validate,:validate_block,:log,:log_block,:log,:log_block,:notify,:notify_block],[:save]]

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :validate_block
        expect(object.order[2]).to be :log
        expect(object.order[3]).to be :log_block
        expect(object.order[4]).to be :save
        expect(object.order[5]).to be :log
        expect(object.order[6]).to be :log_block
        expect(object.order[7]).to be :notify
        expect(object.order[8]).to be :notify_block
        expect(object.order[9]).to be nil

      end

      it 'should run hooks without closure' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate_2, if: proc { run? }
          before_save :validate, -> { order << :validate_block; :validate_block}
          around_save :log, -> { order << :log_block; :log_block }
          after_save :notify, -> { order << :notify_block; :notify_block }
          def run?; false; end
          def validate; order << :validate; :validate; end
          def log; order << :log; :log; end
          def notify; order << :notify; :notify; end
          def save
            run_hooks!(:save, :all, :return_all)
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to eql [[:validate,:validate_block,:log,:log_block,:log,:log_block,:notify,:notify_block],[true]]

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :validate_block
        expect(object.order[2]).to be :log
        expect(object.order[3]).to be :log_block
        expect(object.order[4]).to be :log
        expect(object.order[5]).to be :log_block
        expect(object.order[6]).to be :notify
        expect(object.order[7]).to be :notify_block
        expect(object.order[8]).to be nil

      end

      it 'should halt hooks next to hook that returned false' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate_2, if: proc { run? }
          before_save :validate, -> { order << :validate_block; :validate_block}
          around_save :log, -> { order << :log_block; false }
          after_save :notify, -> { order << :notify_block; :notify_block }
          def run?; false; end
          def validate; order << :validate; :validate; end
          def log; order << :log; :log; end
          def notify; order << :notify; :notify; end
          def save
            run_hooks(:save, :all, :return_all)
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to be false

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :validate_block
        expect(object.order[2]).to be :log
        expect(object.order[3]).to be :log_block
        expect(object.order[8]).to be nil

      end

    end

    context 'Halt Hooks' do
      it 'should halt hooks next to hook that returned false(in case of `before_save` `method`)' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate, if: proc { run? }
          before_save :validate_2, -> { order << :block }, :validate_3
          around_save :log
          after_save :notify
          def run?; false; end
          def validate; order << :validate; end
          def validate_2; order << :validate_2; false; end
          def validate_3; order << :validate_3; end
          def log; order << :log; end
          def notify; order << :notify; end

          def save
            run_hooks(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to be false

        expect(object.order[0]).to be :validate_2
        expect(object.order[1]).to be nil

      end

      it 'should halt hooks next to hook that returned false(in case of `before_save` `closure`)' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate, if: proc { run? }
          before_save :validate_2, -> { order << :block; false }, :validate_3
          around_save :log
          after_save :notify
          def run?; false; end
          def validate; order << :validate; end
          def validate_2; order << :validate_2; end
          def validate_3; order << :validate_3; end
          def log; order << :log; end
          def notify; order << :notify; end

          def save
            run_hooks(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to be false

        expect(object.order[0]).to be :validate_2
        expect(object.order[1]).to be :block
        expect(object.order[2]).to be nil

      end

      it 'should halt hooks next to hook that returned false(in case of `around_save` `method`)' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          around_save :log, :log_2, :log_3
          after_save :notify
          def run?; false; end
          def validate; order << :validate; end
          def log_2; order << :log_2; false; end
          def log_3; order << :log_3; end
          def log; order << :log; end
          def notify; order << :notify; end

          def save
            run_hooks(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to be false

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :log
        expect(object.order[2]).to be :log_2
        expect(object.order[3]).to be nil

      end

      it 'should halt hooks next to hook that returned false(in case of `after_save` `method`)' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          around_save :log
          after_save :notify, :notify_2, :notify_3
          def run?; false; end
          def validate; order << :validate; end
          def notify_2; order << :notify_2; false; end
          def notify_3; order << :notify_3; end
          def log; order << :log; end
          def notify; order << :notify; end

          def save
            run_hooks(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to be false

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :log
        expect(object.order[2]).to be :save
        expect(object.order[3]).to be :log
        expect(object.order[4]).to be :notify
        expect(object.order[5]).to be :notify_2
        expect(object.order[6]).to be nil

      end

      it 'should not halt hooks next to hook that returned nil(in case of method`)' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          around_save :log
          after_save :notify, :notify_2, :notify_3
          def run?; false; end
          def validate; order << :validate; end
          def notify_2; order << :notify_2; nil; end
          def notify_3; order << :notify_3; end
          def log; order << :log; end
          def notify; order << :notify; end

          def save
            run_hooks(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to_not be false

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :log
        expect(object.order[2]).to be :save
        expect(object.order[3]).to be :log
        expect(object.order[4]).to be :notify
        expect(object.order[5]).to be :notify_2
        expect(object.order[6]).to be :notify_3
        expect(object.order[7]).to be nil

      end

      it 'should not halt hooks next to hook that returned nil(in case of closure`)' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate
          around_save :log
          after_save proc { order << :block; nil }, :notify, :notify_2, :notify_3
          def run?; false; end
          def validate; order << :validate; end
          def notify_2; order << :notify_2; end
          def notify_3; order << :notify_3; end
          def log; order << :log; end
          def notify; order << :notify; end

          def save
            run_hooks(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        expect(object.save).to_not be false

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :log
        expect(object.order[2]).to be :save
        expect(object.order[3]).to be :log
        expect(object.order[4]).to be :block
        expect(object.order[5]).to be :notify
        expect(object.order[6]).to be :notify_2
        expect(object.order[7]).to be :notify_3
        expect(object.order[8]).to be nil

      end


    end

  end

  describe 'Skip All hooks' do

    it 'should skip skip all `before_save` hooks' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate, :validate_2, if: proc { run? }
        before_save :validate_3, :validate_4
        after_save :notify
        skip_all_hooks :save, :before
        def run?
          true
        end
        def validate; order << :validate; end
        def validate_2; order << :validate_2; end
        def validate_3; order << :validate_3; end
        def validate_4; order << :validate_4; end
        def notify; order << :notify; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :save
      expect(object.order[1]).to be :notify
      expect(object.order[2]).to be nil

    end

    it 'should skip_all_hooks `around_save` hooks' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        around_save :log, :log_2, if: proc { run? }
        around_save :log_3, :log_4
        after_save :notify
        skip_all_hooks :save, :around
        def run?
          true
        end
        def log; order << :log; end
        def log_2; order << :log_2; end
        def log_3; order << :log_3; end
        def log_4; order << :log_4; end
        def notify; order << :notify; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :save
      expect(object.order[1]).to be :notify
      expect(object.order[2]).to be nil

    end

    it 'should skip_all_hooks `after_save` hooks' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        after_save :notify, :notify_2, if: proc { run? }
        after_save :notify_3, :notify_4
        before_save :validate
        skip_all_hooks :save, :after
        def run?
          true
        end
        def notify; order << :notify; end
        def notify_2; order << :notify_2; end
        def notify_3; order << :notify_3; end
        def notify_4; order << :notify_4; end
        def validate; order << :validate; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :save
      expect(object.order[2]).to be nil

    end

    context 'Conditional Skip All' do

      it 'should `skip_all_hooks` if conditional statement in expression returned `true`' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          after_save :notify, :notify_2, if: proc { run? }
          after_save :notify_3, :notify_4
          before_save :validate
          skip_all_hooks :save, :after, if: proc { ignore? }
          def run?
            false
          end
          def ignore?
            true
          end
          def notify; order << :notify; end
          def notify_2; order << :notify_2; end
          def notify_3; order << :notify_3; end
          def notify_4; order << :notify_4; end
          def validate; order << :validate; end
          def save
            run_hooks!(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :save
        expect(object.order[2]).to be nil

      end

      it 'should not `skip_all_hooks` if conditional statement in expression returned `false`' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          after_save :notify, :notify_2, if: proc { run? }
          after_save :notify_3, :notify_4
          before_save :validate
          skip_all_hooks :save, :after, if: proc { ignore? }
          def run?
            false
          end
          def ignore?
            false
          end
          def notify; order << :notify; end
          def notify_2; order << :notify_2; end
          def notify_3; order << :notify_3; end
          def notify_4; order << :notify_4; end
          def validate; order << :validate; end
          def save
            run_hooks!(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :validate
        expect(object.order[1]).to be :save
        expect(object.order[2]).to be :notify_3
        expect(object.order[3]).to be :notify_4
        expect(object.order[4]).to be nil

      end
    end
  end

  describe 'Skip hooks' do
    it 'should skip hooks' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate_1, :validate_2
        before_save :validate_3, :validate_4
        skip_hook :save, :before, :validate_2, :validate_4
        def validate_1; order << :validate_1; end
        def validate_2; order << :validate_2; end
        def validate_3; order << :validate_3; end
        def validate_4; order << :validate_4; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate_1
      expect(object.order[1]).to be :validate_3
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be nil

    end

    it 'should skip multiple hooks' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate_1, :validate_2
        before_save :validate_3, :validate_4
        skip_hook :save, :before, :validate_2
        skip_hook :save, :before, :validate_4

        def validate_1; order << :validate_1; end
        def validate_2; order << :validate_2; end
        def validate_3; order << :validate_3; end
        def validate_4; order << :validate_4; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      object = klass.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate_1
      expect(object.order[1]).to be :validate_3
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be nil

    end

    context 'Conditional Skip' do

      it 'should skip multiple hooks if `if clause` returned `true` in expression' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate_1, :validate_2
          before_save :validate_3, :validate_4
          skip_hook :save, :before, :validate_2, if: proc { run? }

          def run?; true; end
          def validate_1; order << :validate_1; end
          def validate_2; order << :validate_2; end
          def validate_3; order << :validate_3; end
          def validate_4; order << :validate_4; end
          def save
            run_hooks!(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :validate_1
        expect(object.order[1]).to be :validate_3
        expect(object.order[2]).to be :validate_4
        expect(object.order[3]).to be :save
        expect(object.order[4]).to be nil

      end

      it 'should not skip multiple hooks if `if clause` returned `false` in expression' do

        klass = Class.new do
          include Prong
          attr_accessor :order
          define_hook :save
          before_save :validate_1, :validate_2
          before_save :validate_3, :validate_4
          skip_hook :save, :before, :validate_4
          skip_hook :save, :before, :validate_2, :validate_1, if: proc { run? }

          def run?; false; end
          def validate_1; order << :validate_1; end
          def validate_2; order << :validate_2; end
          def validate_3; order << :validate_3; end
          def validate_4; order << :validate_4; end
          def save
            run_hooks!(:save) do
              order << :save
            end
          end
        end

        object = klass.new
        object.order = []
        object.save

        expect(object.order[0]).to be :validate_1
        expect(object.order[1]).to be :validate_2
        expect(object.order[2]).to be :validate_3
        expect(object.order[3]).to be :save
        expect(object.order[4]).to be nil

      end
    end
  end

  describe 'Inheritence' do

    it 'should run hooks on inherited class' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        around_save :log
        after_save :notify
        def validate; order << :validate; end
        def log; order << :log; end
        def notify; order << :notify; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      inherited = Class.new(klass)

      object = inherited.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :log
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be :log
      expect(object.order[4]).to be :notify
      expect(object.order[5]).to be nil

    end

    it 'should skip hooks on inherited class' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        around_save :log
        after_save :notify
        skip_hook :save, :after, :notify
        def validate; order << :validate; end
        def log; order << :log; end
        def notify; order << :notify; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      inherited = Class.new(klass)

      object = inherited.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :log
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be :log
      expect(object.order[4]).to be nil

    end

    it 'should be able to define new hooks on inherited class' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        around_save :log
        after_save :notify
        skip_hook :save, :after, :notify
        def validate; order << :validate; end
        def log; order << :log; end
        def notify; order << :notify; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      inherited = Class.new(klass) do
        before_save :validate_2
        def validate_2; order << :validate_2; end
      end

      object = inherited.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :validate_2
      expect(object.order[2]).to be :log
      expect(object.order[3]).to be :save
      expect(object.order[4]).to be :log
      expect(object.order[5]).to be nil

    end

    it 'should be able to define & skip hooks on inherited class without effect on parent class' do

      klass = Class.new do
        include Prong
        attr_accessor :order
        define_hook :save
        before_save :validate
        around_save :log
        after_save :notify
        skip_hook :save, :after, :notify
        def validate; order << :validate; end
        def log; order << :log; end
        def notify; order << :notify; end
        def save
          run_hooks!(:save) do
            order << :save
          end
        end
      end

      inherited = Class.new(klass) do
        before_save :validate_2
        skip_all_hooks :save, :around
        def validate_2; order << :validate_2; end
      end

      object = inherited.new
      object.order = []
      object.save

      expect(object.order[0]).to be :validate
      expect(object.order[1]).to be :validate_2
      expect(object.order[2]).to be :save
      expect(object.order[3]).to be nil

      parent_object = klass.new
      parent_object.order = []
      parent_object.save

      expect(parent_object.order[0]).to be :validate
      expect(parent_object.order[1]).to be :log
      expect(parent_object.order[2]).to be :save
      expect(parent_object.order[3]).to be :log
      expect(parent_object.order[4]).to be nil

    end
  end
end
