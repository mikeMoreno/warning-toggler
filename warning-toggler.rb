require_relative "lines"

KNOWN_PROJECTS = []

TARGET_FILE_NAME = "Directory.Build.targets"

def is_file_valid?(file_content)
    if file_content.scan(/TreatWarningsAsErrors/).length > 2 then
        return false
    end

    return true
end

def show_current_status(file_content)

    if file_content.include?("<TreatWarningsAsErrors>true</TreatWarningsAsErrors>") then
        return "enabled"
    end

    if file_content.include?("<TreatWarningsAsErrors>false</TreatWarningsAsErrors>") then
        return "disabled"
    end

    return "unknown"
end

def update_content(command, original_file_content)
    case command
    when "on"
        args = {
            :old => "<TreatWarningsAsErrors>false</TreatWarningsAsErrors>",
            :new => "<TreatWarningsAsErrors>true</TreatWarningsAsErrors>",
        }
    when "off"
        args = {
            :old => "<TreatWarningsAsErrors>true</TreatWarningsAsErrors>",
            :new => "<TreatWarningsAsErrors>false</TreatWarningsAsErrors>",
        }
    end

    new_file_content = original_file_content.sub args[:old], args[:new]

    return new_file_content
end

def write_file(file, new_file_content)

    endings = Lines.get_endings(file)

    File.open(file, 'wb') do |f|
        i = 0

        new_file_content.split("\n").each do |line|

            line_ending = endings[i]

            f.print "#{line}#{line_ending.ending}"
            i+= 1
        end
    end
end

def set_git_tracking(tracking_status, file)
    if tracking_status == :on then
        system("git update-index --no-assume-unchanged #{file}", err: File::NULL)
    else
        system("git update-index --assume-unchanged #{file}", err: File::NULL)
    end
end

def main()
    project_folder = File.basename(Dir.getwd)

    if !KNOWN_PROJECTS.include?(project_folder) then
        puts "What project is this?"
        return
    end

    full_file_name = "#{Dir.getwd}/#{TARGET_FILE_NAME}"

    if !File.exist?(full_file_name) then
        puts "Couldn't find #{full_file_name}"
        return
    end

    original_file_content = File.read(full_file_name)

    if !is_file_valid?(original_file_content) then
        puts "Error: file is malformed"
        return
    end

    if ARGV.length == 0 then
        current_status = show_current_status(original_file_content)
        puts "warnings as errors: #{current_status}"
        return
    end

    command = ARGV[0]

    if command != "on" && command != "off" then
        puts "on or off please"
        return
    end

    new_file_content = update_content(command, original_file_content)

    if original_file_content == new_file_content then
        puts "no changes"
        return
    end

    write_file(full_file_name, new_file_content)

    changes_file = "#{__dir__}/changes_made_#{project_folder}"

    if File.exist?(changes_file) then
        set_git_tracking(:on, full_file_name)

        File.delete(changes_file)
    else
        set_git_tracking(:off, full_file_name)

        File.open(changes_file, 'w') do |f|
            f.puts "changes made"
        end
    end
end

main()
