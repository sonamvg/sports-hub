organizer = User.find_or_create_by!(email: "organizer@example.com") do |user|
  user.name = "Demo Organizer"
  user.password = "password123"
  user.role = :organizer
end
organizer.update!(name: "Demo Organizer", password: "password123", role: :organizer)

parent = User.find_or_create_by!(email: "parent@example.com") do |user|
  user.name = "Demo Parent"
  user.password = "password123"
  user.role = :parent
end
parent.update!(name: "Demo Parent", password: "password123", role: :parent)

academy_owner = User.find_or_create_by!(email: "academy-owner@example.com") do |user|
  user.name = "Demo Academy Owner"
  user.password = "password123"
  user.role = :academy_owner
end
academy_owner.update!(name: "Demo Academy Owner", password: "password123", role: :academy_owner)

super_admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Demo Super Admin"
  user.password = "password123"
  user.role = :super_admin
end
super_admin.update!(name: "Demo Super Admin", password: "password123", role: :super_admin)

deccan_academy = Academy.find_or_initialize_by(name: "Deccan Taekwondo Academy", city: "Pune")
deccan_academy.assign_attributes(
  owner: academy_owner,
  status: :approved,
  reviewed_at: 10.days.ago,
  state: "Maharashtra",
  country: "India",
  contact_name: "Master Kulkarni",
  email: "deccan@example.com",
  phone: "+91 98765 43210"
)
deccan_academy.save!

shivneri_academy = Academy.find_or_initialize_by(name: "Shivneri Martial Arts", city: "Mumbai")
shivneri_academy.assign_attributes(
  owner: academy_owner,
  status: :approved,
  reviewed_at: 7.days.ago,
  state: "Maharashtra",
  country: "India",
  contact_name: "Coach Patil",
  email: "shivneri@example.com",
  phone: "+91 91234 56780"
)
shivneri_academy.save!

pending_academy = Academy.find_or_initialize_by(name: "Nagpur Rising Taekwondo", city: "Nagpur")
pending_academy.assign_attributes(
  owner: academy_owner,
  status: :pending,
  state: "Maharashtra",
  country: "India",
  contact_name: "Coach Deshmukh",
  email: "nagpur-rising@example.com",
  phone: "+91 90000 11111"
)
pending_academy.save!

rejected_academy = Academy.find_or_initialize_by(name: "Incomplete Academy Submission", city: "Nashik")
rejected_academy.assign_attributes(
  owner: academy_owner,
  status: :rejected,
  reviewed_at: 3.days.ago,
  rejection_reason: "Missing registration documentation.",
  state: "Maharashtra",
  country: "India",
  contact_name: "Applicant",
  email: "incomplete@example.com"
)
rejected_academy.save!

athlete_rows = [
  {
    first_name: "Aarohi",
    last_name: "Shah",
    academy: deccan_academy,
    date_of_birth: Date.new(2014, 5, 12),
    gender: "female",
    belt: "red",
    weight: 39.5,
    association_id: "MH-TKD-1001",
    city: "Pune",
    state: "Maharashtra"
  },
  {
    first_name: "Vihaan",
    last_name: "Mehta",
    academy: deccan_academy,
    date_of_birth: Date.new(2012, 3, 3),
    gender: "male",
    belt: "blue",
    weight: 44.2,
    association_id: "MH-TKD-1002",
    city: "Pune",
    state: "Maharashtra"
  },
  {
    first_name: "Anaya",
    last_name: "Iyer",
    academy: shivneri_academy,
    date_of_birth: Date.new(2016, 9, 22),
    gender: "female",
    belt: "green",
    weight: 29.8,
    association_id: "MH-TKD-1003",
    city: "Mumbai",
    state: "Maharashtra"
  }
]

athletes = athlete_rows.each_with_object({}) do |attrs, records|
  athlete = Athlete.find_or_initialize_by(user: parent, first_name: attrs[:first_name], last_name: attrs[:last_name])
  athlete.assign_attributes(attrs)
  athlete.save!
  records[athlete.first_name] = athlete
end

deccan_open = Tournament.find_or_initialize_by(name: "Deccan Taekwondo Open 2026")
deccan_open.assign_attributes(
  organizer: organizer,
  slug: "deccan-taekwondo-open-2026",
  description: "Open kyorugi and poomsae event for cadet and junior athletes.",
  venue: "Balewadi Sports Complex",
  city: "Pune",
  state: "Maharashtra",
  start_date: Date.new(2026, 10, 18),
  end_date: Date.new(2026, 10, 19),
  registration_opens_at: 30.days.ago,
  registration_closes_at: Date.new(2026, 10, 10).in_time_zone,
  status: :registration_open
)
deccan_open.save!

mumbai_cup = Tournament.find_or_initialize_by(name: "Mumbai Junior Taekwondo Cup 2026")
mumbai_cup.assign_attributes(
  organizer: organizer,
  slug: "mumbai-junior-taekwondo-cup-2026",
  description: "Junior-focused event with multiple beginner and intermediate divisions.",
  venue: "Andheri Sports Hall",
  city: "Mumbai",
  state: "Maharashtra",
  start_date: Date.new(2026, 11, 21),
  end_date: Date.new(2026, 11, 22),
  registration_opens_at: 15.days.ago,
  registration_closes_at: Date.new(2026, 11, 10).in_time_zone,
  status: :registration_open
)
mumbai_cup.save!

closed_tournament = Tournament.find_or_initialize_by(name: "Pune Invitational Review Event")
closed_tournament.assign_attributes(
  organizer: organizer,
  slug: "pune-invitational-review-event",
  description: "Closed sample tournament for testing non-open registration states.",
  venue: "Pune District Hall",
  city: "Pune",
  state: "Maharashtra",
  start_date: Date.new(2026, 9, 5),
  end_date: Date.new(2026, 9, 6),
  registration_opens_at: 45.days.ago,
  registration_closes_at: 5.days.ago,
  status: :registration_closed
)
closed_tournament.save!

category_rows = [
  { tournament: deccan_open, event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41, belt_min: "red", belt_max: "black" },
  { tournament: deccan_open, event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 41, weight_max: 45, belt_min: "blue", belt_max: "black" },
  { tournament: deccan_open, event_type: "poomsae", gender: "female", age_min: 10, age_max: 12, belt_min: "green", belt_max: "red" },
  { tournament: mumbai_cup, event_type: "kyorugi", gender: "female", age_min: 10, age_max: 12, weight_max: 32, belt_min: "green", belt_max: "red" },
  { tournament: mumbai_cup, event_type: "kyorugi", gender: "male", age_min: 12, age_max: 14, weight_min: 41, weight_max: 45, belt_min: "blue", belt_max: "red" },
  { tournament: closed_tournament, event_type: "kyorugi", gender: "female", age_min: 12, age_max: 14, weight_max: 41, belt_min: "red", belt_max: "black" }
]

categories = category_rows.map do |attrs|
  category = TournamentCategory.find_or_initialize_by(attrs)
  category.save!
  category
end

Registration.find_or_create_by!(
  tournament_id: deccan_open.id,
  athlete_id: athletes["Aarohi"].id,
  tournament_category_id: categories[0].id
) do |record|
  record.registered_weight = athletes["Aarohi"].weight
  record.status = :approved
  record.verified_at = 2.days.ago
end

Registration.find_or_create_by!(
  tournament_id: mumbai_cup.id,
  athlete_id: athletes["Anaya"].id,
  tournament_category_id: categories[3].id
) do |record|
  record.registered_weight = athletes["Anaya"].weight
  record.status = :pending
end
