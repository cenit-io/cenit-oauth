class User
  include Mongoid::Document
  include Cenit::Oauth::User
  include Mongoid::Attributes::Dynamic

  field :email, type: String
  field :picture

  def confirmed?
    attributes[:confirmed_at].present?
  end
end