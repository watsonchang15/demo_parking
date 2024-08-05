module Uuidable
  extend ActiveSupport::Concern

  included do
    before_create :generate_uuid
  end

  protected

  def generate_uuid
    self.uuid = SecureRandom.uuid
  end
end