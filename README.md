# Prong
Activesupport-like callbacks but upto %20 faster.

# Introduction

Prong is almost behave like ActiveSupport::Callbakcs in most of the cases. It's let you define hooks, add callbacks to them, and conditionally run them whenever you want.

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
  define_hook :save, :update

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
=> true
account.save
=> true
account.password_salt.nil?
=> false
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/prong. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
