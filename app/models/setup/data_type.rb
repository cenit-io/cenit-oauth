module Setup
  class DataType
    include Mongoid::Document
    include Cenit::MultiTenancy::Scoped
    include CrossOrigin::Document

    origins :default, -> { Cenit::MultiTenancy.tenant_model.current && :owner }, :shared, :cenit
  end
end