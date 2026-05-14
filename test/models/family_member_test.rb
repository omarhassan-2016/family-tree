require "test_helper"

class FamilyMemberTest < ActiveSupport::TestCase
  setup do
    @person = Person.create!(first_name: "John", last_name: "Smith", gender: :male)
    @family = Family.create!
  end

  test "requires role" do
    fm = FamilyMember.new(person: @person, family: @family)
    assert_not fm.valid?
    assert_not_empty fm.errors[:role]
  end

  test "prevents duplicate role in same family" do
    FamilyMember.create!(person: @person, family: @family, role: :father)
    duplicate = FamilyMember.new(person: @person, family: @family, role: :father)
    assert_not duplicate.valid?
  end

  test "allows same person with different role in different family" do
    other_family = Family.create!
    FamilyMember.create!(person: @person, family: @family, role: :father)
    fm = FamilyMember.new(person: @person, family: other_family, role: :father)
    assert fm.valid?
  end

  test "role enum values" do
    assert_equal 0, FamilyMember.roles[:father]
    assert_equal 1, FamilyMember.roles[:mother]
    assert_equal 2, FamilyMember.roles[:child]
  end
end
