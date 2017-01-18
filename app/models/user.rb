class User
  include Mongoid::Document
  include Cenit::Oauth::User
  include Mongoid::Attributes::Dynamic

  field :email, type: String
  field :picture

  has_many :accounts, class_name: Account.to_s, inverse_of: :owner

  def confirmed?
    attributes[:confirmed_at].present?
  end
end