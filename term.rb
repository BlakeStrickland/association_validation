class Term < ActiveRecord::Base
  has_many :courses, dependent: :restrict_with_error
  belongs_to :school
  default_scope { order('ends_on DESC') }

  scope :for_school_id, ->(school_id) { where("school_id = ?", school_id) }

  def school_name
    school ? school.name : "None"
  end
end
