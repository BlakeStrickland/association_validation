class Reading < ActiveRecord::Base
  belongs_to :lesson
  belongs_to :course
  validates_format_of :url, :with => /(http|https):\/\//, :on => :create
  validates :order_number, presence: true
  validates :lesson_id, presence: true
  validates :url, presence: true

  default_scope { order('order_number') }

  scope :pre, -> { where("before_lesson = ?", true) }
  scope :post, -> { where("before_lesson != ?", true) }

  def clone
    dup
  end
end
