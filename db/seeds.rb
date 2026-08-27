# Demo seed data for local testing.
#
# These records cover current MVP roles and the newer tournament setup fields:
# per-category fee, payment instructions, courts, referees, categories, athletes,
# approvals, and registration receipt uploads. The script is idempotent.

PASSWORD = "password123"
FIXTURE_DIR = Rails.root.join("test/fixtures/files")
TOURNAMENT_IMAGE = FIXTURE_DIR.join("tournament-image.png")
PAYMENT_RECEIPT = FIXTURE_DIR.join("payment-receipt.png")

def seed_user(email:, name:, role:, **attributes)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(attributes.merge(name: name, role: role, password: PASSWORD, password_confirmation: PASSWORD))
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

super_admin = seed_user(
  email: "admin@sportshub.test",
  name: "Sports Hub Admin",
  role: :super_admin
)

academy_owner = seed_user(
  email: "academy@sportshub.test",
  name: "Pune Academy Owner",
  role: :academy_owner,
  phone: "9000000001"
)

organizer = seed_user(
  email: "organizer@sportshub.test",
  name: "Demo Tournament Organizer",
  role: :organizer,
  organizer_status: :verified,
  organizer_designation: "Tournament Director",
  organizer_approved_at: Time.current,
  organizer_reviewed_by: super_admin,
  phone: "9000000002"
)

assistant_organizer = seed_user(
  email: "assistant.organizer@sportshub.test",
  name: "Assistant Organizer",
  role: :organizer,
  organizer_status: :verified,
  organizer_designation: "Operations Lead",
  organizer_approved_at: Time.current,
  organizer_reviewed_by: super_admin,
  phone: "9000000003"
)

athlete_user = seed_user(
  email: "athlete@sportshub.test",
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
  email: "academy@sportshub.test",
  phone: "020-40000000",
  contact_name: "Pune Academy Owner",
  registration_number: "PCTA-2026-001",
  status: :approved
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

open_tournament = seed_tournament(
  name: "Pune Open Taekwondo Championship",
  organizer: organizer,
  description: "Demo registration-open tournament with categories, payment details, referees, and athletes.",
  venue: "Balewadi Sports Complex",
  city: "Pune",
  state: "Maharashtra",
  country: "India",
  start_date: 45.days.from_now.to_date,
  end_date: 46.days.from_now.to_date,
  registration_opens_at: 3.days.ago,
  registration_closes_at: 30.days.from_now,
  status: :registration_open,
  tournament_level: "State",
  organizing_organization: "Maharashtra Taekwondo Association",
  time_zone: "Mumbai",
  primary_contact_name: "Event Desk",
  primary_contact_email: "events@sportshub.test",
  primary_contact_phone: "9000000200",
  competition_formats: "Kyorugi, Individual Poomsae",
  eligibility_summary: "Age proof required, Valid academy or association membership, Medical fitness declaration",
  category_generation_method: "Default category templates",
  registration_capacity: 250,
  registration_fee: 1000,
  currency: "INR",
  required_documents: "Age proof, Government identity proof, Association ID",
  refund_policy: "Full refund before registration closes, No refund after draws are published",
  payment_account_name: "Maharashtra Taekwondo Association",
  payment_bank_name: "Demo Cooperative Bank",
  payment_account_number: "123456789012",
  payment_ifsc: "DEMO0001234",
  payment_instructions: "Use athlete name and tournament name as payment reference.",
  courts_count: 4,
  website_url: "https://example.com/pune-open"
)

closed_tournament = seed_tournament(
  name: "Mumbai Invitational Taekwondo Cup",
  organizer: organizer,
  description: "Demo post-registration tournament with venue and referee details ready for weight check.",
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
  primary_contact_email: "mumbai.events@sportshub.test",
  primary_contact_phone: "9000000300",
  competition_formats: "Kyorugi",
  eligibility_summary: "Age proof required, Guardian consent for minors",
  category_generation_method: "Default category templates",
  registration_capacity: 180,
  registration_fee: 800,
  currency: "INR",
  required_documents: "Age proof, Academy approval letter",
  refund_policy: "No refund after draws are published",
  payment_account_name: "Mumbai Taekwondo Committee",
  payment_bank_name: "Demo National Bank",
  payment_account_number: "987654321098",
  payment_ifsc: "DEMO0009876",
  payment_instructions: "Use athlete association ID as payment reference.",
  courts_count: 3
)

[open_tournament, closed_tournament].each do |tournament|
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

[
  {
    tournament: open_tournament,
    name: "Meera Rao",
    phone: "9000000401",
    email: "meera.rao@sportshub.test",
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
    email: "arjun.nair@sportshub.test",
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
    email: "farah.khan@sportshub.test",
    role: "Technical official",
    qualification: "WT certified referee",
    certification_id: "WT-IND-778",
    affiliation: "Mumbai Taekwondo Committee",
    notes: "Lead official for weight check and draw desk."
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

seed_registration(
  tournament: open_tournament,
  athlete: athletes.second,
  category: open_categories.second,
  status: :approved,
  actor: organizer
)

seed_registration(
  tournament: closed_tournament,
  athlete: athletes.third,
  category: closed_categories.second,
  status: :approved,
  actor: assistant_organizer
)

puts "Seeded Sports Hub demo data."
puts "Super admin: admin@sportshub.test / #{PASSWORD}"
puts "Organizer: organizer@sportshub.test / #{PASSWORD}"
puts "Academy owner: academy@sportshub.test / #{PASSWORD}"
puts "Athlete: athlete@sportshub.test / #{PASSWORD}"
