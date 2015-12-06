# Prong
Activesupport-like callbacks but upto %20 faster.

# Introduction

Prong is almost behave like ActiveSupport::Callbakcs in most of the cases. It's let you define hooks, add callbacks to them, and conditionally run them whenever you want. Prong is not just another one, It's faster! also there's some differences.

There are some functionalities like `reset_callbacks`,`scope` which unfortunately not supported in version 1.0.0.
I'll add those functionalities in next version.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prong', '~> 1.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install prong

## Usage

Let's start with an Account:

```ruby
class Account
  include Prong
  attr_accessor :password_salt
  define_hook :save

  before_save proc { self.password_salt = Random.srand unless self.password_salt }, :valid?
  # after_save :notify, if: proc {}

  def valid?
    raise unless self.password_salt
  end

  def save
    run_hooks(:save)
  end
end
```
Lets's save account and see what's going to happen
```ruby
account = Account.new
account.password_salt.nil?
# => true
account.save
# => true
account.password_salt.nil?
# => false
```
### Class Methods
#### define_hook
You can define multiple hooks at once with `#define_hook`, each hook defines three sub-hooks on context class `before_*`, `around_*`, `after_*`.
A sub-hook accept multiple arguments
`#define_hook` takes multiple `Symbol` argument.
```ruby
class Account
  include Prong
  define_hook :save, :update
  # Sub-hooks
  # before_save, around_save, after_save, before_update, around_update, after_update
end
```
A sub-hook accept multiple arguments(Proc, Symbol), sub-hook consider last argument as a condition if argument is kind of `Hash` with `if` key. Prong doesn't support `unless` condition like `ActiveSupport::Callbacks` because it's unnecessary.
Condition type must be `proc`! `lambda` doesn't supported.

```ruby
class Account
  include Prong
  define_hook :update
  # Below sub-hook will be executed if condition return true.
  before_update :authorized?, proc { self.updated_at = Time.now }, if: proc { self.changed? }
end
```
### skip_hook
You can skip callbacks in context class or sub classes of context:
```ruby
class Account
  include Prong
  define_hook :save
  around_save :log
  after_save :notify, :notify_to_admin
end

class X < Account
  skip_hook :save, :after, :notify, :notify_to_admin
  skip_hook :save, :around, :log, if: proc { self.log? }
end
```
`#skip_hook` accept condition too.

### skip_all_hooks
You can skip all callbacks in sub-hook with `#skip_all_hooks`
```ruby
class Account
  include Prong
  define_hook :save
  around_save :log
  after_save :notify, :notify_to_admin
end

class X < Account
  skip_all_hooks :save, :after
  skip_all_hooks :save, :around, if: proc { self.skip?  }
end
`#skip_all_hooks` accept condition too.
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/EhsanYousefi/prong. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
