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
begin ; rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def setup
    begin ApplicationMigration.migrate(:down); rescue; end
    ApplicationMigration.migrate(:up)
  end

  def test_truth

    assert true

  end

  def test_schools_and_term_relation

    school = School.create(name: "Education")
    fall = Term.create(name: "Fall", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    spring = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    school.terms << fall
    school.terms << spring

    assert_equal [fall, spring], school.terms.all

  end

  def test_lessons_have_readings_dependent_destroy

    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    reading1 = Reading.create(order_number: 1, lesson_id: 1, url: "https://www.ruby-docs.org", caption: "How many dots can I get?")
    reading2 = Reading.create(order_number: 2, lesson_id: 2, url: "https://www.ruby-docs.org/amazeballs", caption: "I've got a lovely bunch of cocodots, dootaledee")
    lesson.readings << reading1
    lesson.readings << reading2

    assert_equal [reading1, reading2], lesson.readings.all
    lesson.destroy

    assert lesson.destroyed?

  end

  def test_term_has_many_courses_dependent_restrict

    spring = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    wonders_of_basket_weaving = Course.create(course_code: "OOR-111", name: "Basket Weaving")
    spring.courses << wonders_of_basket_weaving

    assert_equal [wonders_of_basket_weaving], spring.courses.all

    spring.destroy

    refute spring.destroyed?

  end

  def test_courses_has_many_lessons_dependent_destroy

    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    wonders_of_basket_weaving = Course.create(course_code: "OOR-111", name: "Basket Weaving")
    wonders_of_basket_weaving.lessons << lesson

    assert_equal [lesson], wonders_of_basket_weaving.lessons.all

    wonders_of_basket_weaving.destroy
    assert wonders_of_basket_weaving.destroyed?

  end

  def test_courses_have_many_students_dependent_restrict_with_error

    racing_101 = Course.create(course_code: "OOR-111", name: "Lets a go!")
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

  end

  def test_courses_has_many_instructors_dependent_restrict_with_error

    make_a_living_with_no_job = Course.create(course_code: "OOR-111", name: "Rupee farming")
    link = CourseInstructor.create(instructor_id: 1)

    make_a_living_with_no_job.course_instructors << link
    assert_equal [link], make_a_living_with_no_job.course_instructors.all

    make_a_living_with_no_job.destroy

    refute make_a_living_with_no_job.destroyed?

  end

  def test_course_has_many_assignments_dependent_destroy

    evil_plan = Course.create(course_code: "OOR-111", name: "muhahahaha")
    black_out_the_sun = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.80)

    evil_plan.assignments << black_out_the_sun
    assert_equal [black_out_the_sun], evil_plan.assignments.all

    evil_plan.destroy
    assert evil_plan.destroyed?

  end

  def test_school_has_many_courses_through_terms

    school = School.create(name: "The Iron Yard")
    term = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    ruby = Course.create(course_code: "OOR-111", name: "Ruby")
    python = Course.create(course_code: "OOR-211", name: "Python")
    front_end = Course.create(course_code: "OOR-311", name: "Front End")

    term.courses << ruby
    term.courses << python
    term.courses << front_end

    school.terms << term

    assert_equal [ruby, python, front_end], school.courses

  end

  def test_course_has_many_readings_through_lessons

    ruby = Course.create(course_code: "OOR-111", name: "Ruby")
    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    reading1 = Reading.create(order_number: 1, lesson_id: 1, url: "https://www.ruby-docs.org", caption: "How many dots can I get?")
    reading2 = Reading.create(order_number: 2, lesson_id: 2, url: "https://www.ruby-docs.org/awesome", caption: "I've got a lovely bunch of cocodots, dootaledee")

    lesson.readings << reading1
    lesson.readings << reading2
    ruby.lessons << lesson

    assert_equal [reading1, reading2], ruby.readings

  end

  def test_lessons_have_names

    lesson = Lesson.create(name: "Integrate databases with Ruby!")
    lesson2 = Lesson.create()

    assert_equal lesson, Lesson.first
    assert_equal lesson, Lesson.last
    assert_equal [lesson], Lesson.all

  end

  def test_readings_have_order_number_lesson_id_and_url

    reading1 = Reading.create(order_number: 1, lesson_id: 1, url: "https://www.ruby-docs.org", caption: "How many dots can I get?")
    reading2 = Reading.create()

    refute reading2.id
    assert_equal reading1.order_number, Reading.first.order_number
    assert_equal reading1.lesson_id, Reading.last.lesson_id
    assert_equal reading1.url, Reading.last.url
    assert_equal [reading1], Reading.all

  end

  def test_courses_have_code_and_name

    ruby = Course.create(course_code: "OOR-111", name: "Ruby")
    shouldnt_be_counted = Course.create()

    refute shouldnt_be_counted.id
    assert_equal ruby, Course.first
    assert_equal ruby, Course.last
    assert_equal [ruby], Course.all


  end

  def test_schools_must_have_names

    iron_yard = School.create(name: "The Iron Yard")
    shouldnt_be_counted = School.create()

    refute shouldnt_be_counted.id
    assert_equal iron_yard, School.first
    assert_equal iron_yard, School.last
    assert_equal [iron_yard], School.all


  end

  def test_terms_must_have_name_start_on_end_on_and_school_id

    spring = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    shouldnt_be_counted = Term.create(name: "blah")

    refute shouldnt_be_counted.id
    assert_equal spring, Term.first
    assert_equal spring, Term.last
    assert_equal [spring], Term.all


  end

  def test_user_must_have_first_name_last_name_and_email

    blake = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome.com")
    shouldnt_be_counted = User.create(first_name: "Blah")

    refute shouldnt_be_counted.id
    assert_equal [blake], User.all


  end

  def test_user_email_cannot_be_duplicated

    blake = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome.com")

    blake2 = User.create(first_name: "Blake2", last_name: "Strickland2", email: "Myself@awesome.com")

    refute blake2.id
    assert_equal [blake], User.all


  end

  def test_assignments_must_have_course_id_name_and_percent_of_grade

    black_out_the_sun = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.80)
    black_out_the_sun2 = Assignment.create(name: "Eternal darkness")

    refute black_out_the_sun2.id
    assert_equal [black_out_the_sun], Assignment.all

  end

  def test_assignments_name_is_unique_with_given_course_id

    black_out_the_sun = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.80)
    black_out_the_sun2 = Assignment.create(course_id: 1, name: "Eternal darkness", percent_of_grade: 0.90)
    black_out_the_sun3 = Assignment.create(course_id: 2, name: "Eternal darkness", percent_of_grade: 0.90)

    assert_equal [black_out_the_sun, black_out_the_sun3], Assignment.all

  end

  def test_lessons_with_pre_class_assignments

    pre_class_assignment = Assignment.create(name: "Ruby Ruby Ruby Ruby!")
    lesson = Lesson.create(name: "Integrate databases with Ruby!")

    lesson.pre_class_assignment = pre_class_assignment
    assert Lesson.where(pre_class_assignment_id: pre_class_assignment.id)


  end

  def test_lessons_with_in_class_assignments

    in_class_assignment = Assignment.create(name: "Ruby Ruby Ruby Ruby!")
    lesson = Lesson.create(name: "Integrate databases with Ruby!")

    lesson.in_class_assignment = in_class_assignment
    assert Lesson.where(in_class_assignment_id: in_class_assignment.id)


  end

  def test_valid_email_using_reg_ex

    blake = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome.com")
    blake2 = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself$awesome.com")

    refute blake2.id
    assert_equal [blake], User.all


  end

  def test_readings_must_have_valid_url

    reading1 = Reading.create(order_number: 1, lesson_id: 1, url: "http://www.ruby-docs.org", caption: "How many dots can I get?")
    reading2 = Reading.create(order_number: 2, lesson_id: 2, url: "https://www.ruby-docs.org/iforgetwhatimdoing", caption: "Another dot?")
    reading3 = Reading.create(order_number: 3, lesson_id: 3, url: "www.ruby-docs.org", caption: "How many dots can I get?")


  end

  def test_course_codes_must_be_unique_through_term_id

    term = Term.create(name: "Spring", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)
    term2 = Term.create(name: "Fall", starts_on: "2016-01-09", ends_on: "2016-03-09", school_id: 1)

    ruby = Course.create(course_code: "OOR-111", name: "Ruby", term_id: 1)
    ruby2 = Course.create(course_code: "OOR-111", name: "Ruby2s", term_id: 2)
    ruby3 = Course.create(course_code: "OOR-111", name: "Ruby2s", term_id: 2)

    refute ruby3.id
    assert_equal [ruby2, ruby], Course.all



  end

  def test_validate_course_code_starts_with_3_letters_and_ends_with_3_numbers

    ruby = Course.create(course_code: "OOR-111", name: "Ruby", term_id: 1)
    ruby2 = Course.create(course_code: 1, name: "Ruby", term_id: 1)

    refute ruby2.id
    assert_equal [ruby], Course.all


  end

  def test_user_photo_url_must_start_with_http_s

    blake = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome.com", photo_url: "http://www.TIY.com")
    blake2 = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome.com", photo_url: "www.TIY.com")
    blake3 = User.create(first_name: "Blake", last_name: "Strickland", email: "Myself@awesome2.com", photo_url: "https://www.TIY.com")

    refute blake2.id
    assert_equal [blake, blake3], User.all

  end
end
