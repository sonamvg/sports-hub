# Clean seed data for local testing and staging demos.
#
# These records cover current MVP roles and the newer tournament setup fields:
# per-category fee, payment instructions, courts, referees, categories, athletes,
# approvals, and registration receipt uploads. The script is idempotent.

PASSWORD = "password123"
FIXTURE_DIR = Rails.root.join("test/fixtures/files")
TOURNAMENT_IMAGE = FIXTURE_DIR.join("tournament-image.png")
PAYMENT_RECEIPT = FIXTURE_DIR.join("payment-receipt.png")

def cleanup_obsolete_seed_data
  obsolete_tournament_names = [
    "Demo Tournament",
    "Test Tournament",
    "Paged Tournament",
    "Placeholder Open",
    "Delete Me Open",
    "Protected Open",
    "Open Invitational"
  ]

  obsolete_tournament_names.each do |name|
    Tournament.where("name ILIKE ?", "#{name}%").find_each(&:destroy)
  end
end

def seed_user(email:, name:, role:, **attributes)
  legacy_email = email.to_s.sub("@podiumcircle.test", "@sportshub.test")
  user = User.where(email: [email, legacy_email]).first || User.new(email: email)
  user.assign_attributes(attributes.merge(name: name, role: role, password: PASSWORD, password_confirmation: PASSWORD))
  user.email = email
  user.save!
  user
end

def attach_file(record, attachment_name, path, content_type:)
  return unless File.exist?(path)

  attachment = record.public_send(attachment_name)
  return if attachment.attached?

  attachment.attach(
    io: File.open(path),
    filename: File.basename(path),
    content_type: content_type
  )
end

def seed_academy(name:, owner:, **attributes)
  academy = Academy.find_or_initialize_by(name: name)
  academy.assign_attributes(attributes.merge(owner: owner))
  academy.save!
  attach_file(academy, :logo_image, TOURNAMENT_IMAGE, content_type: "image/png")
  academy
end

def seed_athlete(user:, academy:, first_name:, last_name:, **attributes)
  athlete = Athlete.find_or_initialize_by(user: user, first_name: first_name, last_name: last_name)
  athlete.assign_attributes(attributes.merge(academy: academy))
  athlete.save!
  attach_file(athlete, :profile_photo, TOURNAMENT_IMAGE, content_type: "image/png")
  athlete
end

def seed_tournament(name:, organizer:, **attributes)
  tournament = Tournament.find_or_initialize_by(name: name)
  tournament.assign_attributes(attributes.merge(organizer: organizer))
  tournament.save!
  attach_file(tournament, :logo_image, TOURNAMENT_IMAGE, content_type: "image/png")
  attach_file(tournament, :banner_image, TOURNAMENT_IMAGE, content_type: "image/png")
  tournament
end

def seed_membership_request(academy:, athlete:, requested_by:)
  return if athlete.academy_id == academy.id

  AcademyMembershipRequest.find_or_create_by!(academy: academy, athlete: athlete, requested_by: requested_by, status: :pending)
end

def seed_category(tournament, template_key)
  template = TournamentCategory.default_template_for(template_key)
  raise "Unknown category template: #{template_key}" unless template

  category = tournament.tournament_categories.find_or_initialize_by(template.except(:key))
  category.save!
  category
end

def seed_registration(tournament:, athlete:, category:, status:, actor:)
  registration = tournament.registrations.find_or_initialize_by(athlete: athlete, tournament_category: category)
  from_status = registration.status if registration.persisted?
  registration.assign_attributes(
    registered_weight: athlete.weight,
    status: status,
    fee_amount: tournament.registration_fee.presence || 0,
    fee_currency: tournament.currency.presence || "INR"
  )
  attach_file(registration, :payment_receipt, PAYMENT_RECEIPT, content_type: "image/png")
  registration.save!

  if status.to_s.in?(%w[approved rejected]) && registration.registration_action_logs.where(action: status).none?
    registration.registration_action_logs.create!(
      actor: actor,
      action: status,
      from_status: from_status || "pending",
      to_status: status
    )
  end

  registration
end

def seed_weight_checks(registration:, actor:, weights:)
  registration.registration_weight_checks.destroy_all
  registration.registration_action_logs.where(action: %w[weight_verified disqualified]).destroy_all
  registration.update!(status: :approved, verified_at: Time.current)

  weights.each do |weight|
    registration.registration_weight_checks.create!(checked_by: actor, weight: weight)
    registration.reload
    break unless registration.approved?
  end

  registration
end

cleanup_obsolete_seed_data

super_admin = seed_user(
  email: "admin@podiumcircle.test",
  name: "PodiumCircle Admin",
  role: :super_admin
)

academy_owner = seed_user(
  email: "academy@podiumcircle.test",
  name: "Pune Academy Owner",
  role: :academy_owner,
  phone: "9000000001"
)

organizer = seed_user(
  email: "organizer@podiumcircle.test",
  name: "Kanchan Surudkar",
  role: :organizer,
  organizer_status: :verified,
  organizer_designation: "Tournament Director",
  organizer_approved_at: Time.current,
  organizer_reviewed_by: super_admin,
  phone: "9000000002"
)

assistant_organizer = seed_user(
  email: "assistant.organizer@podiumcircle.test",
  name: "Nikhil Desai",
  role: :organizer,
  organizer_status: :verified,
  organizer_designation: "Operations Lead",
  organizer_approved_at: Time.current,
  organizer_reviewed_by: super_admin,
  phone: "9000000003"
)

athlete_user = seed_user(
  email: "athlete@podiumcircle.test",
  name: "Aarohi Shah",
  role: :athlete,
  phone: "9000000004"
)

academy = seed_academy(
  name: "Pune Champions Taekwondo Academy",
  owner: academy_owner,
  city: "Pune",
  state: "Maharashtra",
  country: "India",
  email: "academy@podiumcircle.test",
  phone: "020-40000000",
  contact_name: "Pune Academy Owner",
  registration_number: "PCTA-2026-001",
  status: :approved
)

shivneri_owner = seed_user(
  email: "shivneri.owner@podiumcircle.test",
  name: "Madhura Bhide",
  role: :academy_owner,
  phone: "9000000011"
)

deccan_owner = seed_user(
  email: "deccan.owner@podiumcircle.test",
  name: "Rahul Jadhav",
  role: :academy_owner,
  phone: "9000000012"
)

mumbai_owner = seed_user(
  email: "mumbai.owner@podiumcircle.test",
  name: "Naina Merchant",
  role: :academy_owner,
  phone: "9000000013"
)

shivneri_academy = seed_academy(
  name: "Shivneri Martial Arts",
  owner: shivneri_owner,
  city: "Pune",
  state: "Maharashtra",
  country: "India",
  email: "contact@shivnerimartialarts.in",
  phone: "020-41234567",
  contact_name: "Madhura Bhide",
  registration_number: "SMA-2026-014",
  status: :approved
)

deccan_academy = seed_academy(
  name: "Deccan Elite Taekwondo",
  owner: deccan_owner,
  city: "Pune",
  state: "Maharashtra",
  country: "India",
  email: "desk@deccanelitetkd.in",
  phone: "020-42345678",
  contact_name: "Rahul Jadhav",
  registration_number: "DET-2026-022",
  status: :approved
)

mumbai_academy = seed_academy(
  name: "Mumbai Falcons Taekwondo",
  owner: mumbai_owner,
  city: "Mumbai",
  state: "Maharashtra",
  country: "India",
  email: "hello@mumbaifalconstkd.in",
  phone: "022-40123456",
  contact_name: "Naina Merchant",
  registration_number: "MFT-2026-009",
  status: :approved
)

pending_academy = seed_academy(
  name: "Riverfront Combat Academy",
  owner: deccan_owner,
  city: "Nashik",
  state: "Maharashtra",
  country: "India",
  email: "admin@riverfrontcombat.in",
  phone: "0253-4012000",
  contact_name: "Sagar More",
  registration_number: "RCA-2026-031",
  status: :pending
)

SuperAdminNotification.notify!(
  kind: :academy_submission,
  notifiable: pending_academy,
  actor: deccan_owner,
  message: "Riverfront Combat Academy is waiting for academy approval."
)

athletes = [
  seed_athlete(
    user: athlete_user,
    academy: academy,
    first_name: "Aarohi",
    last_name: "Shah",
    date_of_birth: Date.new(2012, 5, 12),
    gender: "female",
    belt: "red",
    weight: 36.8,
    blood_group: "O+",
    association_id: "MTA-ATH-1001",
    contact_number: "9000000101",
    emergency_contact_name: "Ritika Shah",
    emergency_contact_phone: "9000000199",
    address: "Kothrud",
    city: "Pune",
    state: "Maharashtra",
    country: "India",
    government_id_document_type: "Aadhaar"
  ),
  seed_athlete(
    user: academy_owner,
    academy: academy,
    first_name: "Vihaan",
    last_name: "Mehta",
    date_of_birth: Date.new(2011, 9, 20),
    gender: "male",
    belt: "blue",
    weight: 39.2,
    blood_group: "B+",
    association_id: "MTA-ATH-1002",
    contact_number: "9000000102",
    emergency_contact_name: "Nisha Mehta",
    emergency_contact_phone: "9000000299",
    address: "Baner",
    city: "Pune",
    state: "Maharashtra",
    country: "India",
    government_id_document_type: "School ID"
  ),
  seed_athlete(
    user: academy_owner,
    academy: academy,
    first_name: "Kabir",
    last_name: "Patil",
    date_of_birth: Date.new(2009, 1, 8),
    gender: "male",
    belt: "black",
    weight: 52.4,
    blood_group: "A+",
    association_id: "MTA-ATH-1003",
    contact_number: "9000000103",
    emergency_contact_name: "Amol Patil",
    emergency_contact_phone: "9000000399",
    address: "Shivajinagar",
    city: "Pune",
    state: "Maharashtra",
    country: "India",
    government_id_document_type: "Aadhaar"
  )
]

additional_roster_specs = [
  [shivneri_academy, "Ira", "Bapat", "female", Date.new(2015, 4, 8), "yellow", 24.3, "A+", "SMA-ATH-2101", "Kothrud"],
  [shivneri_academy, "Nirav", "Joshi", "male", Date.new(2014, 10, 2), "green", 31.6, "B+", "SMA-ATH-2102", "Erandwane"],
  [shivneri_academy, "Rhea", "Kulkarni", "female", Date.new(2012, 7, 19), "blue", 36.4, "O+", "SMA-ATH-2103", "Karve Nagar"],
  [shivneri_academy, "Omkar", "Deshpande", "male", Date.new(2009, 11, 6), "red", 53.8, "AB+", "SMA-ATH-2104", "Shivajinagar"],
  [deccan_academy, "Anika", "Gadgil", "female", Date.new(2016, 1, 21), "white", 18.7, "O-", "DET-ATH-3101", "Aundh"],
  [deccan_academy, "Vedant", "Kale", "male", Date.new(2013, 3, 17), "green", 36.2, "A-", "DET-ATH-3102", "Pashan"],
  [deccan_academy, "Mira", "Sawant", "female", Date.new(2010, 6, 28), "black", 48.1, "B-", "DET-ATH-3103", "Baner"],
  [deccan_academy, "Shaurya", "Apte", "male", Date.new(2008, 12, 9), "black", 54.4, "AB-", "DET-ATH-3104", "Wakad"],
  [mumbai_academy, "Tanish", "Bora", "male", Date.new(2015, 8, 14), "yellow", 22.6, "B+", "MFT-ATH-4101", "Andheri"],
  [mumbai_academy, "Avni", "Menon", "female", Date.new(2014, 2, 11), "blue", 33.4, "O+", "MFT-ATH-4102", "Bandra"],
  [mumbai_academy, "Reyansh", "Kapoor", "male", Date.new(2011, 5, 24), "red", 40.8, "A+", "MFT-ATH-4103", "Powai"],
  [mumbai_academy, "Zara", "Contractor", "female", Date.new(2007, 9, 30), "black", 56.3, "AB+", "MFT-ATH-4104", "Dadar"]
]

additional_roster_specs.each_with_index do |(student_academy, first_name, last_name, gender, dob, belt, weight, blood_group, association_id, neighborhood), index|
  user = seed_user(
    email: "#{first_name.downcase}.#{last_name.downcase}@podiumcircle.test",
    name: "#{first_name} #{last_name}",
    role: :athlete,
    phone: "90000009#{format('%02d', index + 1)}"
  )

  athletes << seed_athlete(
    user: user,
    academy: student_academy,
    first_name: first_name,
    last_name: last_name,
    date_of_birth: dob,
    gender: gender,
    belt: belt,
    weight: weight,
    blood_group: blood_group,
    association_id: association_id,
    contact_number: "90000009#{format('%02d', index + 1)}",
    emergency_contact_name: "#{last_name} family contact",
    emergency_contact_phone: "90000010#{format('%02d', index + 1)}",
    address: "#{neighborhood}, #{student_academy.city}",
    city: student_academy.city,
    state: student_academy.state,
    country: student_academy.country,
    government_id_document_type: "Aadhaar"
  )
end

open_tournament = seed_tournament(
  name: "Pune Open Taekwondo Championship",
  organizer: organizer,
  description: "State-level competition with registration review, weigh-in operations, and referee coordination.",
  venue: "Balewadi Sports Complex",
  city: "Pune",
  state: "Maharashtra",
  country: "India",
  start_date: 45.days.from_now.to_date,
  end_date: 46.days.from_now.to_date,
  registration_opens_at: 3.days.ago,
  registration_closes_at: 1.day.ago,
  status: :registration_closed,
  tournament_level: "State",
  organizing_organization: "Maharashtra Taekwondo Association",
  time_zone: "Mumbai",
  primary_contact_name: "Event Desk",
  primary_contact_email: "events@puneopentkd.in",
  primary_contact_phone: "9000000200",
  competition_formats: "Kyorugi, Individual Poomsae",
  eligibility_summary: "Age proof required, Valid academy or association membership, Medical fitness declaration",
  category_generation_method: "Default categories",
  registration_capacity: 250,
  registration_fee: 1000,
  currency: "INR",
  required_documents: "Age proof, Government identity proof, Association ID",
  refund_policy: "Full refund before registration closes, No refund after final schedules are published",
  payment_account_name: "Maharashtra Taekwondo Association",
  payment_bank_name: "Maharashtra Cooperative Bank",
  payment_account_number: "412300987654",
  payment_ifsc: "MCBK0004123",
  payment_instructions: "Use athlete name and tournament name as payment reference.",
  courts_count: 4,
  website_url: "https://puneopentkd.in"
)

closed_tournament = seed_tournament(
  name: "Mumbai Invitational Taekwondo Cup",
  organizer: organizer,
  description: "Invitation tournament with completed registration and verified weigh-ins.",
  venue: "Andheri Sports Hall",
  city: "Mumbai",
  state: "Maharashtra",
  country: "India",
  start_date: 10.days.from_now.to_date,
  end_date: 11.days.from_now.to_date,
  registration_opens_at: 40.days.ago,
  registration_closes_at: 2.days.ago,
  status: :registration_closed,
  tournament_level: "District",
  organizing_organization: "Mumbai Taekwondo Committee",
  time_zone: "Mumbai",
  primary_contact_name: "Mumbai Event Desk",
  primary_contact_email: "entries@mumbaiinvitationaltkd.in",
  primary_contact_phone: "9000000300",
  competition_formats: "Kyorugi",
  eligibility_summary: "Age proof required, Guardian consent for minors",
  category_generation_method: "Default categories",
  registration_capacity: 180,
  registration_fee: 800,
  currency: "INR",
  required_documents: "Age proof, Academy approval letter",
  refund_policy: "No refund after final schedules are published",
  payment_account_name: "Mumbai Taekwondo Committee",
  payment_bank_name: "Western India Bank",
  payment_account_number: "508800765432",
  payment_ifsc: "WIBK0005088",
  payment_instructions: "Use athlete association ID as payment reference.",
  courts_count: 3
)

bengaluru_organizer = seed_user(
  email: "bengaluru.organizer@podiumcircle.test",
  name: "Priya Raman",
  role: :organizer,
  organizer_status: :verified,
  organizer_designation: "Event Convenor",
  organizer_approved_at: Time.current,
  organizer_reviewed_by: super_admin,
  phone: "9000000014"
)

upcoming_tournament = seed_tournament(
  name: "Bengaluru Classic Taekwondo League",
  organizer: bengaluru_organizer,
  description: "Open registration league for academies and independent athletes across South India.",
  venue: "Koramangala Indoor Arena",
  city: "Bengaluru",
  state: "Karnataka",
  country: "India",
  start_date: 70.days.from_now.to_date,
  end_date: 71.days.from_now.to_date,
  registration_opens_at: 1.day.ago,
  registration_closes_at: 35.days.from_now,
  status: :registration_open,
  tournament_level: "Regional",
  organizing_organization: "Karnataka Taekwondo Events Council",
  time_zone: "Asia/Kolkata",
  primary_contact_name: "League Registration Desk",
  primary_contact_email: "entries@bengaluruclassictkd.in",
  primary_contact_phone: "9000000310",
  competition_formats: "Kyorugi, Individual Poomsae, Team Poomsae",
  eligibility_summary: "Age proof required, Valid academy or association membership, Medical fitness declaration",
  category_generation_method: "Default categories",
  registration_capacity: 320,
  registration_fee: 1200,
  currency: "INR",
  required_documents: "Age proof, Government identity proof, Academy approval letter",
  refund_policy: "Partial refund after registration closes, Refund only if event is cancelled",
  payment_account_name: "Karnataka Taekwondo Events Council",
  payment_bank_name: "South City Bank",
  payment_account_number: "601200889900",
  payment_ifsc: "SCBK0006012",
  payment_instructions: "Use athlete full name and selected category count as the payment note.",
  courts_count: 5,
  website_url: "https://bengaluruclassictkd.in"
)

completed_tournament = seed_tournament(
  name: "Delhi Winter Taekwondo Festival",
  organizer: assistant_organizer,
  description: "Completed national festival used for athlete history, results, medals, and archive views.",
  venue: "Talkatora Indoor Stadium",
  city: "New Delhi",
  state: "Delhi",
  country: "India",
  start_date: 40.days.ago.to_date,
  end_date: 39.days.ago.to_date,
  registration_opens_at: 90.days.ago,
  registration_closes_at: 55.days.ago,
  status: :completed,
  tournament_level: "National",
  organizing_organization: "Delhi Taekwondo Council",
  time_zone: "Asia/Kolkata",
  primary_contact_name: "Festival Office",
  primary_contact_email: "office@delhiwintertkd.in",
  primary_contact_phone: "9000000320",
  competition_formats: "Kyorugi, Individual Poomsae",
  eligibility_summary: "Age proof required, Medical fitness declaration",
  category_generation_method: "Default categories",
  registration_capacity: 420,
  registration_fee: 1500,
  currency: "INR",
  required_documents: "Age proof, Government identity proof, Association ID",
  refund_policy: "No refund after final schedules are published",
  payment_account_name: "Delhi Taekwondo Council",
  payment_bank_name: "Capital Sports Bank",
  payment_account_number: "772200110099",
  payment_ifsc: "CSBK0007722",
  payment_instructions: "Closed event. Payment records are retained for audit history.",
  courts_count: 6,
  website_url: "https://delhiwintertkd.in"
)

[open_tournament, closed_tournament, upcoming_tournament, completed_tournament].each do |tournament|
  TournamentOrganizer.find_or_create_by!(tournament: tournament, user: assistant_organizer) do |membership|
    membership.role = :collaborator
    membership.added_by = organizer
  end
end

open_categories = %w[cadet-female-u37 cadet-male-u41 junior-male-u55 individual-poomsae-female-cadet].map do |key|
  seed_category(open_tournament, key)
end

closed_categories = %w[cadet-female-u37 junior-male-u55 senior-male-u68].map do |key|
  seed_category(closed_tournament, key)
end

upcoming_categories = %w[sub-junior-female-u24 cadet-female-u37 cadet-male-u41 junior-male-u55 senior-female-u57 individual-poomsae-male-junior].map do |key|
  seed_category(upcoming_tournament, key)
end

completed_categories = %w[cadet-female-u37 cadet-male-u41 junior-female-u49 junior-male-u55 senior-female-u57 senior-male-u68].map do |key|
  seed_category(completed_tournament, key)
end

[
  {
    tournament: open_tournament,
    name: "Meera Rao",
    phone: "9000000401",
    email: "meera.rao@podiumcircle.test",
    role: "Center referee",
    qualification: "National referee",
    certification_id: "NR-102",
    affiliation: "Maharashtra Taekwondo Association",
    notes: "Available for court one and finals."
  },
  {
    tournament: open_tournament,
    name: "Arjun Nair",
    phone: "9000000402",
    email: "arjun.nair@podiumcircle.test",
    role: "Judge",
    qualification: "State referee",
    certification_id: "SR-211",
    affiliation: "Pune Referee Board",
    notes: "Can support poomsae scoring."
  },
  {
    tournament: closed_tournament,
    name: "Farah Khan",
    phone: "9000000403",
    email: "farah.khan@podiumcircle.test",
    role: "Technical official",
    qualification: "WT certified referee",
    certification_id: "WT-IND-778",
    affiliation: "Mumbai Taekwondo Committee",
    notes: "Lead official for weight check desk."
  }
].each do |attributes|
  referee = attributes.delete(:tournament).tournament_referees.find_or_initialize_by(name: attributes[:name])
  referee.assign_attributes(attributes)
  referee.save!
  attach_file(referee, :photo, TOURNAMENT_IMAGE, content_type: "image/png")
end

seed_registration(
  tournament: open_tournament,
  athlete: athletes.first,
  category: open_categories.first,
  status: :pending,
  actor: organizer
)

vihaan_pune_registration = seed_registration(
  tournament: open_tournament,
  athlete: athletes.second,
  category: open_categories.second,
  status: :approved,
  actor: organizer
)

weight_check_athlete_specs = [
  {
    email: "anaya.kulkarni@podiumcircle.test",
    first_name: "Anaya",
    last_name: "Kulkarni",
    date_of_birth: Date.new(2012, 2, 18),
    gender: "female",
    belt: "blue",
    weight: 38.5,
    blood_group: "AB+",
    association_id: "MTA-WC-2001",
    contact_number: "9000000501",
    emergency_contact_name: "Priya Kulkarni",
    emergency_contact_phone: "9000000591",
    address: "Aundh",
    category: open_categories.first,
    status: :approved,
    weights: [38.5, 38.3]
  },
  {
    email: "saanvi.joshi@podiumcircle.test",
    first_name: "Saanvi",
    last_name: "Joshi",
    date_of_birth: Date.new(2012, 8, 9),
    gender: "female",
    belt: "red",
    weight: 37.0,
    blood_group: "O-",
    association_id: "MTA-WC-2002",
    contact_number: "9000000502",
    emergency_contact_name: "Neha Joshi",
    emergency_contact_phone: "9000000592",
    address: "Wakad",
    category: open_categories.first,
    status: :approved,
    weights: [37.0]
  },
  {
    email: "ishaan.deshmukh@podiumcircle.test",
    first_name: "Ishaan",
    last_name: "Deshmukh",
    date_of_birth: Date.new(2011, 11, 25),
    gender: "male",
    belt: "red",
    weight: 42.2,
    blood_group: "B-",
    association_id: "MTA-WC-2003",
    contact_number: "9000000503",
    emergency_contact_name: "Rohan Deshmukh",
    emergency_contact_phone: "9000000593",
    address: "Viman Nagar",
    category: open_categories.second,
    status: :approved,
    weights: [42.2, 41.8, 41.4]
  },
  {
    email: "rehan.shaikh@podiumcircle.test",
    first_name: "Rehan",
    last_name: "Shaikh",
    date_of_birth: Date.new(2009, 3, 14),
    gender: "male",
    belt: "black",
    weight: 54.2,
    blood_group: "A-",
    association_id: "MTA-WC-2004",
    contact_number: "9000000504",
    emergency_contact_name: "Aamir Shaikh",
    emergency_contact_phone: "9000000594",
    address: "Hadapsar",
    category: open_categories.third,
    status: :approved,
    weights: []
  }
]

weight_check_registrations = weight_check_athlete_specs.map do |spec|
  user = seed_user(
    email: spec[:email],
    name: "#{spec[:first_name]} #{spec[:last_name]}",
    role: :athlete,
    phone: spec[:contact_number]
  )

  athlete = seed_athlete(
    user: user,
    academy: academy,
    first_name: spec[:first_name],
    last_name: spec[:last_name],
    date_of_birth: spec[:date_of_birth],
    gender: spec[:gender],
    belt: spec[:belt],
    weight: spec[:weight],
    blood_group: spec[:blood_group],
    association_id: spec[:association_id],
    contact_number: spec[:contact_number],
    emergency_contact_name: spec[:emergency_contact_name],
    emergency_contact_phone: spec[:emergency_contact_phone],
    address: spec[:address],
    city: "Pune",
    state: "Maharashtra",
    country: "India",
    government_id_document_type: "Aadhaar"
  )

  registration = seed_registration(
    tournament: open_tournament,
    athlete: athlete,
    category: spec[:category],
    status: spec[:status],
    actor: organizer
  )

  seed_weight_checks(registration: registration, actor: assistant_organizer, weights: spec[:weights]) if spec[:weights].any?
  registration
end

seed_weight_checks(registration: vihaan_pune_registration, actor: organizer, weights: [41.5, 40.9])

seed_registration(
  tournament: closed_tournament,
  athlete: athletes.third,
  category: closed_categories.second,
  status: :approved,
  actor: assistant_organizer
)

upcoming_registration_pairs = [
  [athletes[0], upcoming_categories.second, :pending],
  [athletes[3], upcoming_categories.first, :approved],
  [athletes[5], upcoming_categories.second, :approved],
  [athletes[7], upcoming_categories.third, :pending],
  [athletes[10], upcoming_categories.third, :rejected],
  [athletes[13], upcoming_categories.fifth, :pending]
]

upcoming_registration_pairs.each do |student, category, status|
  seed_registration(
    tournament: upcoming_tournament,
    athlete: student,
    category: category,
    status: status,
    actor: bengaluru_organizer
  )
end

completed_registration_pairs = [
  [athletes[0], completed_categories.first, :weight_verified],
  [athletes[4], completed_categories.first, :weight_verified],
  [athletes[6], completed_categories.third, :weight_verified],
  [athletes[8], completed_categories.fourth, :weight_verified],
  [athletes[11], completed_categories.fifth, :disqualified],
  [athletes[14], completed_categories.fifth, :weight_verified]
]

completed_registration_pairs.each_with_index do |(student, category, status), index|
  registration = seed_registration(
    tournament: completed_tournament,
    athlete: student,
    category: category,
    status: :approved,
    actor: assistant_organizer
  )
  if status == :disqualified
    seed_weight_checks(registration: registration, actor: assistant_organizer, weights: [student.weight + 2, student.weight + 1.5, student.weight + 1])
  else
    seed_weight_checks(registration: registration, actor: assistant_organizer, weights: [student.weight])
  end
  registration.update!(status: status)
  registration.update!(registration_number: "DWTF-#{format('%03d', index + 1)}") if registration.registration_number.blank?
end

independent_user = seed_user(
  email: "independent.athlete@podiumcircle.test",
  name: "Samar Vaidya",
  role: :athlete,
  phone: "9000000115"
)

independent_athlete = seed_athlete(
  user: independent_user,
  academy: nil,
  first_name: "Samar",
  last_name: "Vaidya",
  date_of_birth: Date.new(2013, 12, 3),
  gender: "male",
  belt: "green",
  weight: 36.9,
  blood_group: "B+",
  association_id: "IND-ATH-5101",
  contact_number: "9000000115",
  emergency_contact_name: "Vaidya family contact",
  emergency_contact_phone: "9000001115",
  address: "Model Colony, Pune",
  city: "Pune",
  state: "Maharashtra",
  country: "India",
  government_id_document_type: "Aadhaar",
  external_academy_name: "Model Colony Taekwondo Circle"
)

SuperAdminNotification.notify!(
  kind: :unregistered_academy_athlete,
  notifiable: independent_athlete,
  actor: independent_user,
  message: "Samar Vaidya listed Model Colony Taekwondo Circle, which is not registered yet."
)

seed_membership_request(
  academy: shivneri_academy,
  athlete: athletes[10],
  requested_by: athletes[10].user
)

[open_tournament, closed_tournament, upcoming_tournament].each do |tournament|
  SuperAdminNotification.notify!(
    kind: :tournament_submission,
    notifiable: tournament,
    actor: tournament.organizer,
    message: "#{tournament.name} is available for super-admin review."
  )
end

puts "Seeded PodiumCircle local data."
puts "Super admin: admin@podiumcircle.test / #{PASSWORD}"
puts "Organizer: organizer@podiumcircle.test / #{PASSWORD}"
puts "Academy owner: academy@podiumcircle.test / #{PASSWORD}"
puts "Athlete: athlete@podiumcircle.test / #{PASSWORD}"
