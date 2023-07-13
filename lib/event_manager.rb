# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'


def clean_zipcode(zipcode)
  (zipcode || '').rjust(5, '0')[0..4]
end

def remove_non_numeric(string)
  string.delete('^0-9')
end

def good_phone_number?(number)
  return false if number.length < 10 || number.length > 11

  return false if number.length == 11 && !number.start_with?('1')

  true
end

def create_civic_info_access(key)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = key
  civic_info
end

def legislators_by_zipcode(zipcode)
  civic_info = create_civic_info_access('AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw')
  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') { |file| file.puts form_letter }
end

def calculate_peak_hour(array)
  h = array.reduce(Hash.new(0)) do |hash, h|
    hash[h] += 1
    hash
  end
  h.max_by { |key, val| val}[0]
end

def calculate_peak_weekday(array)
  # 0 -> Sunday
  calculate_peak_hour(array)
end

puts 'EventManager initialized'

csv_filename = 'event_attendees.csv'
template_filename = 'form_letter.erb'

exit unless File.exist? csv_filename
exit unless File.exist? template_filename

template_letter = File.read(template_filename)
erb_template = ERB.new template_letter

hours = []
wdays = []
CSV.open(csv_filename, headers: true, header_converters: :symbol).each do |row|
  
  # time targeting
  reg_date = row[:regdate]
  reg_time = Time.strptime(reg_date, '%m/%d/%y %H:%M')
  hours.push(reg_time.hour)
  wdays.push(reg_time.wday)

  next
  # clean  phone numbers
  phone_number = remove_non_numeric(row[:homephone])
  good_number = good_phone_number? phone_number
  
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

end

p calculate_peak_hour(hours)
p calculate_peak_weekday(wdays)