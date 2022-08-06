puts 'Event Manager initialized'
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

#contents = File.read('event_attendees.csv')
#puts contents

### Iteration 0
# lines = File.readlines('event_attendees.csv')
# lines.each_with_index do |line, index|
#   next if index == 0
#   columns = line.split(',')
#   name = columns[2]
#   puts name
# end

### Iteraion 1
# contents = CSV.open(
#   'event_attendees.csv',
#   headers: true,
#   header_converters: :symbol
# )

# contents.each do |row|
#   name = row[:first_name]
#   zipcode = row[:zipcode]
#   puts "#{name} #{zipcode}"
# end

### Iteration 2 and 3 and 4
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_number(number)
  number = number.gsub(/[^0-9]/, "")
  return 'Bad number' if number.length < 10 || number.length > 11 || number.length == 11 && number.chr != '1'
  return number if number.length == 10
  return number.slice(1..10) if number.length == 11 && number.chr == '1'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials # Iteration 4

    legislators = legislators.officials
    legislator_names = legislators.map(&:name)  #Iteration 3
    legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)


template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours_array = []
days_array = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  number = clean_number(row[:homephone])

  date = row[:regdate]

  time = Time.strptime(date, "%y/%d/%m %k:%M")
  hour = time.hour
  hours_array << hour

  date_for_days = Date.strptime(date, "%y/%d/%m %k:%M")
  weekday = date_for_days.wday
  days_array << weekday

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  puts "#{name} #{zipcode} #{number} #{date} #{time} #{hour} #{weekday} #{legislators}"
end



def find_peakhour(array)
  peak_hours = Hash.new()

  array.each do |hour|
    if peak_hours[hour].nil?
      peak_hours[hour] = 1
    else
      peak_hours[hour] += 1
    end
  end
  peak_hours.sort.to_h
end

p find_peakhour(hours_array)

def find_peakday(array)
  peak_days = Hash.new()

  array.each do |day|
    if peak_days[day].nil?
      peak_days[day] = 1
    else
      peak_days[day] += 1
    end
  end
  puts "0 is Sunday"
  peak_days.sort.to_h
end

p find_peakday(days_array)
