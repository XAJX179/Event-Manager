# frozen_string_literal: true

require 'csv'
require 'google-apis-civicinfo_v2'
require 'erb'

puts 'Event Manager initialized!'

def clean_time(val, hours, days)
  time = Time.strptime(val, '%m/%d/%y %k:%M')
  hours[time.hour] += 1
  days[time.strftime('%A')] += 1
  time.strftime('%d-%b-%y %A at %k o\'clock')
end

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
  FileUtils.mkdir_p 'output'
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
  hours = Hash.new(0)
  days = Hash.new(0)
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    hour = clean_time(row[:regdate], hours, days)
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

  def print_time_data(data)
    data.each do |k, v|
      puts "On #{k} registrations = #{v}"
    end
  end

  def find_peak(data)
    data.select do |_k, v|
      v >= 2
    end
  end
  good_hour = find_peak(hours)
  good_days = find_peak(days)
  puts '======Peak Hours======'
  print_time_data(good_hour)
  puts '=======Peak Days====='
  print_time_data(good_days)

else
  puts 'No such file exists.'
end
