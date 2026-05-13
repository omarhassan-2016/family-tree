require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  setup do
    @husband = Person.create!(first_name: "John", last_name: "Smith", gender: :male)
    @wife = Person.create!(first_name: "Jane", last_name: "Doe", gender: :female)
    @kid = Person.create!(first_name: "Alice", last_name: "Smith", gender: :female)

    @family = Family.create!(marriage_date: Date.new(1978, 8, 15))
    FamilyMember.create!(person: @husband, family: @family, role: :father)
    FamilyMember.create!(person: @wife, family: @family, role: :mother)
    FamilyMember.create!(person: @kid, family: @family, role: :child)
  end

  test "father returns the father" do
    assert_equal @husband, @family.father
  end

  test "mother returns the mother" do
    assert_equal @wife, @family.mother
  end

  test "children returns children" do
    assert_includes @family.children, @kid
    assert_equal 1, @family.children.count
  end

  test "parents returns both parents" do
    parents = @family.parents
    assert_includes parents, @husband
    assert_includes parents, @wife
  end
end
