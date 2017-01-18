class Account
  include Mongoid::Document
  include Cenit::MultiTenancy

  belongs_to :owner, class_name: User.to_s, inverse_of: :accounts

end