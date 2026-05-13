# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding family tree data..."

# Clear existing data
FamilyMember.destroy_all
Family.destroy_all
Person.destroy_all

# === Generation 1: Great-Grandparents ===
ggf = Person.create!(first_name: "William", last_name: "Smith", gender: :male,
                      birth_date: Date.new(1890, 3, 10), death_date: Date.new(1965, 11, 22),
                      birth_place: "London, England")
ggm = Person.create!(first_name: "Eleanor", last_name: "Brown", gender: :female,
                      birth_date: Date.new(1893, 7, 4), death_date: Date.new(1970, 5, 18),
                      birth_place: "Manchester, England")

# === Generation 2: Grandparents ===
gf = Person.create!(first_name: "Robert", last_name: "Smith", gender: :male,
                     birth_date: Date.new(1920, 6, 15), death_date: Date.new(1995, 2, 10),
                     birth_place: "Liverpool, England")
gm = Person.create!(first_name: "Mary", last_name: "Johnson", gender: :female,
                     birth_date: Date.new(1922, 9, 20),
                     birth_place: "Dublin, Ireland")

gf_maternal = Person.create!(first_name: "Harold", last_name: "Williams", gender: :male,
                              birth_date: Date.new(1918, 1, 30), death_date: Date.new(1988, 8, 5),
                              birth_place: "Edinburgh, Scotland")
gm_maternal = Person.create!(first_name: "Dorothy", last_name: "Taylor", gender: :female,
                              birth_date: Date.new(1921, 12, 3),
                              birth_place: "Glasgow, Scotland")

# === Generation 3: Parents ===
father = Person.create!(first_name: "John", last_name: "Smith", gender: :male,
                         birth_date: Date.new(1950, 1, 10),
                         birth_place: "New York, USA")
mother = Person.create!(first_name: "Margaret", last_name: "Williams", gender: :female,
                         maiden_name: "Williams",
                         birth_date: Date.new(1952, 5, 25),
                         birth_place: "Boston, USA")
uncle = Person.create!(first_name: "James", last_name: "Smith", gender: :male,
                        birth_date: Date.new(1953, 4, 8),
                        birth_place: "New York, USA")
aunt = Person.create!(first_name: "Susan", last_name: "Davis", gender: :female,
                       birth_date: Date.new(1955, 10, 14),
                       birth_place: "Chicago, USA")

# === Generation 4: Children ===
child1 = Person.create!(first_name: "Alice", last_name: "Smith", gender: :female,
                         birth_date: Date.new(1980, 9, 1),
                         birth_place: "San Francisco, USA")
child2 = Person.create!(first_name: "Bob", last_name: "Smith", gender: :male,
                         birth_date: Date.new(1983, 11, 12),
                         birth_place: "San Francisco, USA")
child3 = Person.create!(first_name: "Carol", last_name: "Smith", gender: :female,
                         birth_date: Date.new(1986, 3, 28),
                         birth_place: "Los Angeles, USA")
cousin1 = Person.create!(first_name: "David", last_name: "Smith", gender: :male,
                          birth_date: Date.new(1982, 7, 19),
                          birth_place: "Chicago, USA")

# === Generation 5: Grandchildren ===
alice_spouse = Person.create!(first_name: "Michael", last_name: "Chen", gender: :male,
                               birth_date: Date.new(1979, 2, 14),
                               birth_place: "San Jose, USA")
grandchild1 = Person.create!(first_name: "Emma", last_name: "Chen", gender: :female,
                              birth_date: Date.new(2010, 6, 22),
                              birth_place: "San Francisco, USA")
grandchild2 = Person.create!(first_name: "Liam", last_name: "Chen", gender: :male,
                              birth_date: Date.new(2013, 8, 30),
                              birth_place: "San Francisco, USA")

# === Family Units ===

# Great-grandparents family: William + Eleanor → Robert
f1 = Family.create!(marriage_date: Date.new(1915, 4, 12), marriage_place: "London, England")
FamilyMember.create!(person: ggf, family: f1, role: :father)
FamilyMember.create!(person: ggm, family: f1, role: :mother)
FamilyMember.create!(person: gf, family: f1, role: :child)

# Paternal grandparents family: Robert + Mary → John, James
f2 = Family.create!(marriage_date: Date.new(1945, 6, 1), marriage_place: "Liverpool, England")
FamilyMember.create!(person: gf, family: f2, role: :father)
FamilyMember.create!(person: gm, family: f2, role: :mother)
FamilyMember.create!(person: father, family: f2, role: :child)
FamilyMember.create!(person: uncle, family: f2, role: :child)

# Maternal grandparents family: Harold + Dorothy → Margaret
f3 = Family.create!(marriage_date: Date.new(1944, 12, 20), marriage_place: "Edinburgh, Scotland")
FamilyMember.create!(person: gf_maternal, family: f3, role: :father)
FamilyMember.create!(person: gm_maternal, family: f3, role: :mother)
FamilyMember.create!(person: mother, family: f3, role: :child)

# Parents' family: John + Margaret → Alice, Bob, Carol
f4 = Family.create!(marriage_date: Date.new(1978, 8, 15), marriage_place: "New York, USA")
FamilyMember.create!(person: father, family: f4, role: :father)
FamilyMember.create!(person: mother, family: f4, role: :mother)
FamilyMember.create!(person: child1, family: f4, role: :child)
FamilyMember.create!(person: child2, family: f4, role: :child)
FamilyMember.create!(person: child3, family: f4, role: :child)

# Uncle's family: James + Susan → David
f5 = Family.create!(marriage_date: Date.new(1980, 5, 10), marriage_place: "Chicago, USA")
FamilyMember.create!(person: uncle, family: f5, role: :father)
FamilyMember.create!(person: aunt, family: f5, role: :mother)
FamilyMember.create!(person: cousin1, family: f5, role: :child)

# Alice's family: Alice + Michael → Emma, Liam
f6 = Family.create!(marriage_date: Date.new(2008, 10, 5), marriage_place: "San Francisco, USA")
FamilyMember.create!(person: alice_spouse, family: f6, role: :father)
FamilyMember.create!(person: child1, family: f6, role: :mother)
FamilyMember.create!(person: grandchild1, family: f6, role: :child)
FamilyMember.create!(person: grandchild2, family: f6, role: :child)

puts "Seeded #{Person.count} people, #{Family.count} families, #{FamilyMember.count} family memberships."
