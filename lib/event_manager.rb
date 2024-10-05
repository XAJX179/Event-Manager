# frozen_string_literal: true

require 'csv'
require 'google-apis-civicinfo_v2'

puts 'Event Manager initialized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def get_legislators_names(zipcode)
  civicinfo = Google::Apis::CivicinfoV2::CivicInfoService.new
  civicinfo.key = File.read('key.key').strip

  legislators = civicinfo.representative_info_by_address(
    address: zipcode,
    levels: 'country',
    roles: %w[legislatorUpperBody legislatorLowerBody]
  ).officials
  legislators.map(&:name).join(', ')
end
if File.exist? 'form_letter.html'
  template = File.read('form_letter.html')
else
  puts 'No such file exists.'
end

if File.exist? 'event_attendees.csv'
  contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
  contents.each do |row|
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    begin
      legislators_names = get_legislators_names(zipcode)
    rescue StandardError
      puts 'try typing zip code next time.'
    end
    personal_letter = template.gsub('FIRST_NAME', name)
    personal_letter.gsub!('LEGISLATORS', legislators_names)

    puts personal_letter
  end
else
  puts 'No such file exists.'
end
