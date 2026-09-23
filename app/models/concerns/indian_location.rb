# Shared reference data used anywhere the app collects an address (Academy,
# Athlete, Tournament venue): the Indian states/UTs for the state dropdown,
# a short country list for the country dropdown, and the PIN code format.
module IndianLocation
  STATES = [
    "Andaman and Nicobar Islands", "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar",
    "Chandigarh", "Chhattisgarh", "Dadra and Nagar Haveli and Daman and Diu", "Delhi", "Goa",
    "Gujarat", "Haryana", "Himachal Pradesh", "Jammu and Kashmir", "Jharkhand", "Karnataka",
    "Kerala", "Ladakh", "Lakshadweep", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya",
    "Mizoram", "Nagaland", "Odisha", "Puducherry", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
  ].freeze

  COUNTRIES = [
    "India", "Bangladesh", "Bhutan", "Nepal", "Sri Lanka", "Pakistan",
    "United Arab Emirates", "Singapore", "United Kingdom", "United States", "Canada", "Australia"
  ].freeze

  PINCODE_FORMAT = /\A[1-9][0-9]{5}\z/
end
