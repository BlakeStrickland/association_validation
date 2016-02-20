# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'
require 'active_record'
require './school.rb'
require './term.rb'
# Include both the migration and the app itself
require './migration'
require './application'
ActiveRecord::Migration.verbose = false


# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end

  def test_schools_and_term_relation
    school = School.create(name: "Education")
    fall = Term.create(name: "Fall")
    spring = Term.create(name: "Spring")
    school.terms << fall
    school.terms << spring

    assert_equal [fall, spring], school.terms.all
  end

  def test_lessons_have_readings_dependent_destroy
    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    reading1 = Reading.create(caption: "How many dots can I get?")
    reading2 = Reading.create(caption: "I've got a lovely bunch of cocodots, dootaledee")
    lesson.readings << reading1
    lesson.readings << reading2

    assert_equal [reading1, reading2], lesson.readings.all
    lesson.destroy

    assert lesson.destroyed?
  end

  def test_term_has_many_courses_dependent_restrict
    spring = Term.create(name: "Spring")
    wonders_of_basket_weaving = Course.create(name: "Basket Weaving")
    spring.courses << wonders_of_basket_weaving

    assert_equal [wonders_of_basket_weaving], spring.courses.all

    spring.destroy

    refute spring.destroyed?
  end

  def test_courses_has_many_lessons_dependent_destroy
    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    wonders_of_basket_weaving = Course.create(name: "Basket Weaving")
    wonders_of_basket_weaving.lessons << lesson

    assert_equal [lesson], wonders_of_basket_weaving.lessons.all

    wonders_of_basket_weaving.destroy
    assert wonders_of_basket_weaving.destroyed?
  end














end
