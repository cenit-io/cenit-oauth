class User
  include Mongoid::Document
  Cenit::MultiTenancy::UserScope
  include Mongoid::Attributes::Dynamic

  def confirmed?
    attributes[:confirmed_at].present?
  end
end