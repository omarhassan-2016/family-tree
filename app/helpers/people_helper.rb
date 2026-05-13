module PeopleHelper
  def gender_icon(person)
    case person.gender
    when "male" then "♂"
    when "female" then "♀"
    else "⚪"
    end
  end
end
