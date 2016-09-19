class User
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  def confirmed?
    attributes[:confirmed_at].present?
  end
end

Cenit::MultiTenancy.user_model User