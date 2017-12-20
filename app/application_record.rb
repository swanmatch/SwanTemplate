class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

#  include CustomValidaters

  scope :deleted, -> { where.not(deleted_at: nil)}
  scope :active, -> { where(deleted_at: nil)}
  scope :column_symbols, -> { column_names.map(&:to_sym) }
#  records_with_operator_on :create, :update, :destroy
#  belongs_to :creater, class_name: "MUser", foreign_key: :created_by
#  belongs_to :updater, class_name: "MUser", foreign_key: :updated_by
#  before_save -> { self.deleted_by = nil if self.deleted_at.blank? }

  # 論理削除
  def logical_delete!
    self.deleted_at = Time.zone.now
#    self.deleted_by = operator.try(:id)
    self.save!(validate: false)
  end

  def deleted?
    self.deleted_at.present?
  end

  def active?
    self.deleted_at.blank?
  end

end
