# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding 40 generations of a single family lineage..."

# Clear existing data
FamilyMember.destroy_all
Family.destroy_all
Person.destroy_all

# Generation 1
father = Person.create!(
  first_name: "Ancestor 1", 
  last_name: "Generation 1", 
  gender: :male, 
  birth_date: Date.new(1000, 1, 1)
)
mother = Person.create!(
  first_name: "Matriarch 1", 
  last_name: "Generation 1", 
  gender: :female, 
  birth_date: Date.new(1002, 5, 12)
)

40.times do |i|
  gen = i + 1
  
  # The family unit
  family = Family.create!(marriage_date: father.birth_date + 20.years)
  FamilyMember.create!(person: father, family: family, role: :father)
  FamilyMember.create!(person: mother, family: family, role: :mother)
  
  if gen < 40
    # The child of this generation becomes the father/mother of the next
    child_gender = [:male, :female].sample
    child_first_name = child_gender == :male ? "Descendant #{gen + 1}" : "Descendant #{gen + 1}"
    
    child = Person.create!(
      first_name: child_first_name, 
      last_name: "Generation #{gen + 1}", 
      gender: child_gender,
      birth_date: father.birth_date + 25.years
    )
    
    FamilyMember.create!(person: child, family: family, role: :child)
    
    # Create the spouse for the child so they can start the next generation family
    spouse_gender = child_gender == :male ? :female : :male
    spouse_first_name = spouse_gender == :male ? "Spouse #{gen + 1}" : "Spouse #{gen + 1}"
    
    spouse = Person.create!(
      first_name: spouse_first_name,
      last_name: "Generation #{gen + 1}",
      gender: spouse_gender,
      birth_date: child.birth_date - 1.year
    )
    
    # Set up for next iteration
    if child.male?
      father = child
      mother = spouse
    else
      father = spouse
      mother = child
    end
  end
end

puts "Seeded #{Person.count} people, #{Family.count} families, #{FamilyMember.count} family memberships."
