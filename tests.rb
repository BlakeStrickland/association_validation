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
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    assert true
    ApplicationMigration.migrate(:down)
  end

  def test_schools_and_term_relation
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    school = School.create(name: "Education")
    fall = Term.create(name: "Fall", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    spring = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    school.terms << fall
    school.terms << spring

    assert_equal [fall, spring], school.terms.all
    ApplicationMigration.migrate(:down)
  end

  def test_lessons_have_readings_dependent_destroy
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    reading1 = Reading.create(order_number: 1, lesson_id: 1, url: "www.ruby-docs.org", caption: "How many dots can I get?")
    reading2 = Reading.create(order_number: 2, lesson_id: 2, url: "www.ruby-docs.org/amazeballs", caption: "I've got a lovely bunch of cocodots, dootaledee")
    lesson.readings << reading1
    lesson.readings << reading2

    assert_equal [reading1, reading2], lesson.readings.all
    lesson.destroy

    assert lesson.destroyed?
    ApplicationMigration.migrate(:down)
  end

  def test_term_has_many_courses_dependent_restrict
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    spring = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    wonders_of_basket_weaving = Course.create(course_code: 1, name: "Basket Weaving")
    spring.courses << wonders_of_basket_weaving

    assert_equal [wonders_of_basket_weaving], spring.courses.all

    spring.destroy

    refute spring.destroyed?
    ApplicationMigration.migrate(:down)
  end

  def test_courses_has_many_lessons_dependent_destroy
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    wonders_of_basket_weaving = Course.create(course_code: 1, name: "Basket Weaving")
    wonders_of_basket_weaving.lessons << lesson

    assert_equal [lesson], wonders_of_basket_weaving.lessons.all

    wonders_of_basket_weaving.destroy
    assert wonders_of_basket_weaving.destroyed?
    ApplicationMigration.migrate(:down)
  end

  def test_courses_have_many_students_dependent_restrict_with_error
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    racing_101 = Course.create(course_code: 1, name: "Lets a go!")
    mario = CourseStudent.create(student_id: 1)
    luigi = CourseStudent.create(student_id: 2)
    peach = CourseStudent.create(student_id: 3)
    toad = CourseStudent.create(student_id: 4)

    racing_101.course_students << mario
    racing_101.course_students << luigi
    racing_101.course_students << peach
    racing_101.course_students << toad

    assert_equal [mario, luigi, peach, toad], racing_101.course_students.all

    racing_101.destroy

    refute racing_101.destroyed?
    ApplicationMigration.migrate(:down)
  end

  def test_courses_has_many_instructors_dependent_restrict_with_error
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    make_a_living_with_no_job = Course.create(course_code: 1, name: "Rupee farming")
    link = CourseInstructor.create(instructor_id: 1)

    make_a_living_with_no_job.course_instructors << link
    assert_equal [link], make_a_living_with_no_job.course_instructors.all

    make_a_living_with_no_job.destroy

    refute make_a_living_with_no_job.destroyed?
    ApplicationMigration.migrate(:down)
  end

  def test_course_has_many_assignments_dependent_destroy
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    evil_plan = Course.create(course_code: 1, name: "muhahahaha")
    black_out_the_sun = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.80)

    evil_plan.assignments << black_out_the_sun
    assert_equal [black_out_the_sun], evil_plan.assignments.all

    evil_plan.destroy
    assert evil_plan.destroyed?
    ApplicationMigration.migrate(:down)
  end

  def test_school_has_many_courses_through_terms
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    school = School.create(name: "The Iron Yard")
    term = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    ruby = Course.create(course_code: 1, name: "Ruby")
    python = Course.create(course_code: 2, name: "Python")
    front_end = Course.create(course_code: 3, name: "Front End")

    term.courses << ruby
    term.courses << python
    term.courses << front_end

    school.terms << term

    assert_equal [ruby, python, front_end], school.courses
    ApplicationMigration.migrate(:down)
  end

  def test_course_has_many_readings_through_lessons
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    ruby = Course.create(course_code: 1, name: "Ruby")
    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    reading1 = Reading.create(order_number: 1, lesson_id: 1, url: "www.ruby-docs.org", caption: "How many dots can I get?")
    reading2 = Reading.create(order_number: 2, lesson_id: 2, url: "www.ruby-docs.org/awesome", caption: "I've got a lovely bunch of cocodots, dootaledee")

    lesson.readings << reading1
    lesson.readings << reading2
    ruby.lessons << lesson

    assert_equal [reading1, reading2], ruby.readings
    ApplicationMigration.migrate(:down)
  end

  def test_lessons_have_names
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    lesson2 = Lesson.create()

    assert_equal lesson, Lesson.first
    assert_equal lesson, Lesson.last
    assert_equal [lesson], Lesson.all
    ApplicationMigration.migrate(:down)
  end

  def test_readings_have_order_number_lesson_id_and_url
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    reading1 = Reading.create(order_number: 1, lesson_id: 1, url: "www.ruby-docs.org", caption: "How many dots can I get?")
    reading2 = Reading.create()

    refute reading2.id
    assert_equal reading1.order_number, Reading.first.order_number
    assert_equal reading1.lesson_id, Reading.last.lesson_id
    assert_equal reading1.url, Reading.last.url
    assert_equal [reading1], Reading.all
    ApplicationMigration.migrate(:down)
  end

  def test_courses_have_code_and_name
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    ruby = Course.create(course_code: 1, name: "Ruby")
    shouldnt_be_counted = Course.create()

    refute shouldnt_be_counted.id
    assert_equal ruby, Course.first
    assert_equal ruby, Course.last
    assert_equal [ruby], Course.all

    ApplicationMigration.migrate(:down)
  end

  def test_schools_must_have_names
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    iron_yard = School.create(name: "The Iron Yard")
    shouldnt_be_counted = School.create()

    refute shouldnt_be_counted.id
    assert_equal iron_yard, School.first
    assert_equal iron_yard, School.last
    assert_equal [iron_yard], School.all

    ApplicationMigration.migrate(:down)
  end

  def test_terms_must_have_name_start_on_end_on_and_school_id
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    spring = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    shouldnt_be_counted = Term.create(name: "blah")

    refute shouldnt_be_counted.id
    assert_equal spring, Term.first
    assert_equal spring, Term.last
    assert_equal [spring], Term.all

    ApplicationMigration.migrate(:down)
  end

  def test_user_must_have_first_name_last_name_and_email
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    blake = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome.com")
    shouldnt_be_counted = User.create(first_name: "Blah")

    refute shouldnt_be_counted.id
    assert_equal [blake], User.all

    ApplicationMigration.migrate(:down)
  end

  def test_user_email_cannot_be_duplicated
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    blake = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome.com")

    blake2 = User.create(first_name: "Blake2", last_name: "Strickland2", email: "Myself@awesome.com")

    refute blake2.id
    assert_equal [blake], User.all

    ApplicationMigration.migrate(:down)
  end

  def test_assignments_must_have_course_id_name_and_percent_of_grade
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    black_out_the_sun = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.80)
    black_out_the_sun2 = Assignment.create(name: "Eternal darkness")

    refute black_out_the_sun2.id
    assert_equal [black_out_the_sun], Assignment.all
    ApplicationMigration.migrate(:down)
  end

  def test_assignments_name_is_unique_with_given_course_id
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)

    black_out_the_sun = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.80)

    black_out_the_sun = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.90)

    ApplicationMigration.migrate(:down)
  end
end
