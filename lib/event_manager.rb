# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
  (zipcode || '').rjust(5, '0')[0..4]
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

puts 'EventManager initialized'

csv_filename = 'event_attendees.csv'
template_filename = 'form_letter.erb'

exit unless File.exist? csv_filename
exit unless File.exist? template_filename

template_letter = File.read(template_filename)
erb_template = ERB.new template_letter

CSV.open(csv_filename, headers: true, header_converters: :symbol).each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

end
