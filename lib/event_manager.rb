# frozen_string_literal: true

require 'csv'
require 'google-apis-civicinfo_v2'
require 'erb'

puts 'Event Manager initialized!'

def clean_phone_no(number)
  num = number.scan(/[0-9]/).join
  if num.length == 10
    num
  elsif num.length == 11
    num[1..] if num[0] == '1'
  else
    'Bad number'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def get_legislators_names(zipcode)
  civicinfo = Google::Apis::CivicinfoV2::CivicInfoService.new
  civicinfo.key = File.read('key.key').strip

  civicinfo.representative_info_by_address(
    address: zipcode,
    levels: 'country',
    roles: %w[legislatorUpperBody legislatorLowerBody]
  ).officials
end

def save_letter(id, form_letter)
  Dir.mkdir 'output' unless Dir.exist? 'output'
  file_name = "output/thanks_#{id}.html"
  File.open(file_name, 'w') do |file|
    file.puts form_letter
  end
end

if File.exist? 'form_letter.erb'
  template = File.read('form_letter.erb')
else
  puts 'No such file exists.'
end

if File.exist? 'event_attendees.csv'
  contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    begin
      number = clean_phone_no(row[:homephone])
      zipcode = clean_zipcode(row[:zipcode])
      legislators = get_legislators_names(zipcode)
      erb_template = ERB.new template
      form_letter = erb_template.result(binding)
      save_letter(id, form_letter)
    rescue StandardError
      puts "Error rescued :#{name}"
    end
  end
else
  puts 'No such file exists.'
end
