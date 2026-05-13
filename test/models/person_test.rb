require "test_helper"

class PersonTest < ActiveSupport::TestCase
  setup do
    @grandfather = Person.create!(first_name: "Robert", last_name: "Smith", gender: :male,
                                  birth_date: Date.new(1920, 3, 15))
    @grandmother = Person.create!(first_name: "Mary", last_name: "Johnson", gender: :female,
                                  birth_date: Date.new(1922, 7, 20))
    @father = Person.create!(first_name: "John", last_name: "Smith", gender: :male,
                             birth_date: Date.new(1950, 1, 10))
    @mother = Person.create!(first_name: "Jane", last_name: "Doe", gender: :female,
                             birth_date: Date.new(1952, 5, 25))
    @child1 = Person.create!(first_name: "Alice", last_name: "Smith", gender: :female,
                             birth_date: Date.new(1980, 9, 1))
    @child2 = Person.create!(first_name: "Bob", last_name: "Smith", gender: :male,
                             birth_date: Date.new(1983, 11, 12))

    # Grandparents' family: Robert + Mary → John
    @gp_family = Family.create!(marriage_date: Date.new(1945, 6, 1))
    FamilyMember.create!(person: @grandfather, family: @gp_family, role: :father)
    FamilyMember.create!(person: @grandmother, family: @gp_family, role: :mother)
    FamilyMember.create!(person: @father, family: @gp_family, role: :child)

    # Parents' family: John + Jane → Alice, Bob
    @p_family = Family.create!(marriage_date: Date.new(1978, 8, 15))
    FamilyMember.create!(person: @father, family: @p_family, role: :father)
    FamilyMember.create!(person: @mother, family: @p_family, role: :mother)
    FamilyMember.create!(person: @child1, family: @p_family, role: :child)
    FamilyMember.create!(person: @child2, family: @p_family, role: :child)
  end

  # --- Validations ---

  test "requires first_name" do
    person = Person.new(last_name: "Smith")
    assert_not person.valid?
    assert_includes person.errors[:first_name], "can't be blank"
  end

  test "full_name concatenates names" do
    assert_equal "Alice Smith", @child1.full_name
  end

  test "full_name handles missing last_name" do
    person = Person.create!(first_name: "Madonna")
    assert_equal "Madonna", person.full_name
  end

  # --- Relationship Traversals ---

  test "parents returns father and mother" do
    parents = @child1.parents
    assert_includes parents, @father
    assert_includes parents, @mother
    assert_equal 2, parents.count
  end

  test "children returns all children" do
    kids = @father.children
    assert_includes kids, @child1
    assert_includes kids, @child2
    assert_equal 2, kids.count
  end

  test "spouses returns partner" do
    assert_includes @father.spouses, @mother
    assert_includes @mother.spouses, @father
  end

  test "spouses does not include self" do
    assert_not_includes @father.spouses, @father
  end

  test "siblings returns brothers and sisters" do
    sibs = @child1.siblings
    assert_includes sibs, @child2
    assert_not_includes sibs, @child1
  end

  test "person with no family returns empty relations" do
    loner = Person.create!(first_name: "Hermit")
    assert_empty loner.parents
    assert_empty loner.children
    assert_empty loner.spouses
    assert_empty loner.siblings
  end

  test "multi-generational traversal" do
    # Alice's father's parents = grandparents
    grandparents = @child1.parents.first { |p| p == @father }&.parents || @father.parents
    assert_includes grandparents, @grandfather
    assert_includes grandparents, @grandmother
  end

  # --- Search ---

  test "search by first name" do
    results = Person.search("Alice")
    assert_includes results, @child1
  end

  test "search by last name" do
    results = Person.search("Smith")
    assert_includes results, @father
    assert_includes results, @child1
  end

  test "search by full name" do
    results = Person.search("John Smith")
    assert_includes results, @father
  end

  test "search is case insensitive" do
    results = Person.search("alice")
    assert_includes results, @child1
  end

  test "search with blank query returns none" do
    assert_empty Person.search("")
    assert_empty Person.search(nil)
  end

  # --- Life Span ---

  test "life_span with birth and death" do
    @grandfather.update!(death_date: Date.new(1995, 2, 10))
    assert_equal "1920 – 1995", @grandfather.life_span
  end

  test "life_span with only birth" do
    assert_equal "1950", @father.life_span
  end

  test "life_span with no dates" do
    person = Person.create!(first_name: "Unknown")
    assert_nil person.life_span
  end
end
