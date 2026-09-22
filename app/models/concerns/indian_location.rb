# Shared India state/city reference data used anywhere the app collects an
# address (Academy, Athlete, Tournament venue) — keeping city choices scoped
# to the selected state so combinations like "Hyderabad" + "Karnataka" can't
# be picked. Not an exhaustive gazetteer: each state lists its major cities:
# an "Other" option in every city dropdown covers anything not listed here,
# so this never blocks a legitimate address, it only prevents obviously wrong
# combinations for the common case.
module IndianLocation
  STATE_CITIES = {
    "Andaman and Nicobar Islands" => ["Port Blair"],
    "Andhra Pradesh" => ["Visakhapatnam", "Vijayawada", "Guntur", "Nellore", "Tirupati", "Kurnool", "Kakinada", "Rajahmundry"],
    "Arunachal Pradesh" => ["Itanagar", "Naharlagun", "Pasighat"],
    "Assam" => ["Guwahati", "Silchar", "Dibrugarh", "Jorhat", "Nagaon", "Tezpur"],
    "Bihar" => ["Patna", "Gaya", "Bhagalpur", "Muzaffarpur", "Darbhanga", "Purnia"],
    "Chandigarh" => ["Chandigarh"],
    "Chhattisgarh" => ["Raipur", "Bhilai", "Bilaspur", "Korba", "Durg"],
    "Dadra and Nagar Haveli and Daman and Diu" => ["Silvassa", "Daman", "Diu"],
    "Delhi" => ["New Delhi", "Dwarka", "Rohini", "Saket", "Karol Bagh"],
    "Goa" => ["Panaji", "Margao", "Vasco da Gama", "Mapusa"],
    "Gujarat" => ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Bhavnagar", "Jamnagar", "Gandhinagar"],
    "Haryana" => ["Gurugram", "Faridabad", "Panipat", "Ambala", "Hisar", "Rohtak", "Karnal"],
    "Himachal Pradesh" => ["Shimla", "Manali", "Dharamshala", "Solan", "Mandi"],
    "Jammu and Kashmir" => ["Srinagar", "Jammu", "Anantnag", "Baramulla"],
    "Jharkhand" => ["Ranchi", "Jamshedpur", "Dhanbad", "Bokaro", "Deoghar"],
    "Karnataka" => ["Bengaluru", "Mysuru", "Hubballi", "Mangaluru", "Belagavi", "Kalaburagi", "Davanagere"],
    "Kerala" => ["Thiruvananthapuram", "Kochi", "Kozhikode", "Thrissur", "Kollam", "Kannur"],
    "Ladakh" => ["Leh", "Kargil"],
    "Lakshadweep" => ["Kavaratti"],
    "Madhya Pradesh" => ["Bhopal", "Indore", "Jabalpur", "Gwalior", "Ujjain", "Sagar"],
    "Maharashtra" => ["Mumbai", "Pune", "Nagpur", "Nashik", "Thane", "Aurangabad", "Solapur", "Kolhapur"],
    "Manipur" => ["Imphal", "Thoubal"],
    "Meghalaya" => ["Shillong", "Tura"],
    "Mizoram" => ["Aizawl", "Lunglei"],
    "Nagaland" => ["Kohima", "Dimapur"],
    "Odisha" => ["Bhubaneswar", "Cuttack", "Rourkela", "Berhampur", "Sambalpur"],
    "Puducherry" => ["Puducherry", "Karaikal"],
    "Punjab" => ["Ludhiana", "Amritsar", "Jalandhar", "Patiala", "Bathinda", "Mohali"],
    "Rajasthan" => ["Jaipur", "Jodhpur", "Udaipur", "Kota", "Ajmer", "Bikaner"],
    "Sikkim" => ["Gangtok", "Namchi"],
    "Tamil Nadu" => ["Chennai", "Coimbatore", "Madurai", "Tiruchirappalli", "Salem", "Tirunelveli", "Erode"],
    "Telangana" => ["Hyderabad", "Warangal", "Nizamabad", "Karimnagar", "Khammam"],
    "Tripura" => ["Agartala", "Udaipur"],
    "Uttar Pradesh" => ["Lucknow", "Kanpur", "Noida", "Ghaziabad", "Agra", "Varanasi", "Meerut", "Prayagraj"],
    "Uttarakhand" => ["Dehradun", "Haridwar", "Rishikesh", "Haldwani", "Roorkee"],
    "West Bengal" => ["Kolkata", "Howrah", "Durgapur", "Asansol", "Siliguri"]
  }.freeze

  STATES = STATE_CITIES.keys.freeze

  OTHER_CITY = "Other".freeze

  PINCODE_FORMAT = /\A[1-9][0-9]{5}\z/

  def self.cities_for(state)
    STATE_CITIES.fetch(state.to_s, [])
  end
end
