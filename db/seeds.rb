# Create demo organization
demo_org = Organization.find_or_create_by!(slug: "demo-org") do |org|
  org.name = "Demo Organization"
  org.active = true
end
puts "Created/found demo organization: #{demo_org.name}"

# Create demo user (admin)
demo_user = User.find_or_initialize_by(email: "demo@pactapp.com")
if demo_user.new_record?
  demo_user.assign_attributes(
    password: "demo1234",
    password_confirmation: "demo1234",
    first_name: "Demo",
    last_name: "User",
    role: :admin,
    organization: demo_org
  )
  demo_user.save!
  puts "Created demo user: demo@pactapp.com / demo1234"
else
  demo_user.update!(organization: demo_org) if demo_user.organization.nil?
  puts "Demo user already exists: demo@pactapp.com / demo1234"
end

# Create additional demo users
additional_users = [
  { email: "member@pactapp.com", first_name: "Team", last_name: "Member", role: :member }
]

additional_users.each do |user_attrs|
  user = User.find_or_initialize_by(email: user_attrs[:email])
  if user.new_record?
    user.assign_attributes(
      password: "demo1234",
      password_confirmation: "demo1234",
      first_name: user_attrs[:first_name],
      last_name: user_attrs[:last_name],
      role: user_attrs[:role],
      organization: demo_org
    )
    user.save!
    puts "Created user: #{user.email}"
  else
    user.update!(organization: demo_org) if user.organization.nil?
  end
end

# Create sample contacts
sample_contacts = [
  { first_name: "Sarah", last_name: "Johnson", email: "sarah.johnson@techcorp.com", phone: "(555) 123-4567", company: "TechCorp Inc", title: "VP of Operations" },
  { first_name: "Michael", last_name: "Chen", email: "mchen@innovate.io", phone: "(555) 234-5678", company: "Innovate.io", title: "CTO" },
  { first_name: "Emily", last_name: "Rodriguez", email: "emily.r@startupxyz.com", phone: "(555) 345-6789", company: "StartupXYZ", title: "Founder" },
  { first_name: "James", last_name: "Williams", email: "jwilliams@globalretail.com", phone: "(555) 456-7890", company: "Global Retail Co", title: "Director of Sales" },
  { first_name: "Lisa", last_name: "Thompson", email: "lthompson@mediahub.net", phone: "(555) 567-8901", company: "MediaHub Networks", title: "Marketing Manager" },
  { first_name: "David", last_name: "Park", email: "dpark@financeplus.com", phone: "(555) 678-9012", company: "FinancePlus", title: "Operations Lead" },
  { first_name: "Amanda", last_name: "Foster", email: "afoster@healthtech.org", phone: "(555) 789-0123", company: "HealthTech Solutions", title: "Business Development" },
  { first_name: "Robert", last_name: "Kim", email: "rkim@constructco.com", phone: "(555) 890-1234", company: "ConstructCo", title: "Project Manager" },
  { first_name: "Jennifer", last_name: "Martinez", email: "jmartinez@legalease.com", phone: "(555) 901-2345", company: "LegalEase LLP", title: "Managing Partner", linkedin_url: "https://linkedin.com/in/jmartinez" },
  { first_name: "Christopher", last_name: "Lee", email: "clee@greentech.eco", phone: "(555) 012-3456", company: "GreenTech Solutions", title: "Sustainability Director" },
  { first_name: "Rachel", last_name: "Green", email: "rgreen@fashionforward.com", phone: "(555) 111-2222", company: "Fashion Forward Inc", title: "Head of Retail" },
  { first_name: "Thomas", last_name: "Anderson", email: "tanderson@matrixsystems.net", phone: "(555) 222-3333", company: "Matrix Systems", title: "IT Director", linkedin_url: "https://linkedin.com/in/tanderson" },
  { first_name: "Nicole", last_name: "Brown", email: "nbrown@edutech.org", phone: "(555) 333-4444", company: "EduTech Academy", title: "Academic Director" },
  { first_name: "Kevin", last_name: "White", email: "kwhite@sportspro.com", phone: "(555) 444-5555", company: "SportsPro Equipment", title: "Sales Director" },
  { first_name: "Stephanie", last_name: "Davis", email: "sdavis@cloudnine.io", phone: "(555) 555-6666", company: "CloudNine Software", title: "VP Engineering", linkedin_url: "https://linkedin.com/in/sdavis" }
]

sample_contacts.each do |contact_data|
  contact = Contact.find_or_initialize_by(email: contact_data[:email], organization: demo_org)
  if contact.new_record?
    contact.assign_attributes(contact_data)
    contact.save!
    contact.contact_assignments.create!(user: demo_user)
  end
end

puts "Seeded #{Contact.count} contacts"

puts ""
puts "=" * 50
puts "DEMO ACCOUNT CREDENTIALS"
puts "=" * 50
puts "Email:    demo@pactapp.com"
puts "Password: demo1234"
puts "=" * 50
puts ""
puts "Additional test account (same password):"
puts "- member@pactapp.com (Member role)"
puts "=" * 50
