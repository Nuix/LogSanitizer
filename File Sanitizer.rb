require "csv"
require "java"
require 'pathname'
require 'rubygems'
require 'zip'
require 'find'

java_import javax.swing.JOptionPane
java_import javax.swing.JFileChooser
java_import javax.swing.filechooser.FileNameExtensionFilter
java_import javax.swing.JDialog
java_import org.apache.commons.io.FileUtils

#Shows a dialog allowing the user to select a directory

def show_options(message,options,default=nil,title="Options")
	if default.nil?
		default = options[0]
	end
	choice = JOptionPane.showInputDialog(nil,message,title,JOptionPane::PLAIN_MESSAGE,nil,options.to_java(:Object),default)
	return choice
end

def prompt_directory(initial_directory=nil,title="Choose Directory")
	fc = JFileChooser.new
	fc.setDialogTitle(title)
	if !initial_directory.nil?
		fc.setCurrentDirectory(java.io.File.new(initial_directory))
	end
	fc.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
	if fc.showOpenDialog(nil) == JFileChooser::APPROVE_OPTION
		file = fc.getSelectedFile
		return file
	end
end
#Shows a dialog allowing the user to pick a file
def prompt_open_file(initial_directory=nil,filters=nil,title="Open CSV File")
	fc = JFileChooser.new
	fc.setDialogTitle(title)
	if !filters.nil?
		fnef = nil
		filters.each do |k,v|
			fnef = FileNameExtensionFilter.new(k,*v)
			fc.addChoosableFileFilter(fnef)
		end
		fc.setFileFilter(fnef)
	end

	if !initial_directory.nil?
		fc.setCurrentDirectory(java.io.File.new(initial_directory))
	end

	if fc.showOpenDialog(nil) == JFileChooser::APPROVE_OPTION
		return fc.getSelectedFile
	else
		return java.io.File.new("")
	end
end

class Logger
	class << self
		attr_accessor :log_file
		def log(obj)
			message = "#{Time.now.strftime("%Y%m%d %H:%M:%S")}: #{obj}"
			puts message
			File.open(@log_file,"a"){|f|f.puts message}
		end
	end
end

message = "Please choose the type of files you want to sanitize."
sanitize_file_choices = ["*.log", "*.txt", "*.xml", "*.fbi2", "*.properties", "*.serverconf"]
sanitize_file_choice = show_options(message,sanitize_file_choices,nil,"Sanitize File Choice")
puts sanitize_file_choice.to_s

#Logger.log_file = "#{File.dirname(__FILE__)}\\#{time_stamp}_Log.txt"

regex_csv_file = prompt_open_file("C:\\",{"Regex CSV File (*.csv)"=>["csv"]},"Choose Regular Expression CSV File")
if regex_csv_file.nil? || !regex_csv_file.exists?
	Logger.log "User did not provide a backup directory"
	exit 1
end

regex_csv_data = CSV.read(regex_csv_file.to_s,  encoding: "bom|utf-8", headers: :first_row)

log_directory = prompt_directory("C:\\","Choose Log Directory")
if log_directory.nil? || !log_directory.exists?
	Logger.log "User did not select a log directory"
	exit 1
end
#Logger.log "Backup Directory: #{backup_directory.getAbsolutePath}"

file_path_filename_regex = Regexp.new("\\b([a-zA-Z]+:(\\\\[^\\\\]+)+[^\\\\]+\\.[^\\. ]+)\\b")
file_path_filename_regex1 = Regexp.new("\\b([a-zA-Z]+:(/[^/]+)+[^/]+\.[^/. ]+)\\b")
file_path_regex = Regexp.new("[a-zA-Z]:/.*")
file_path_regex1 = Regexp.new("[a-zA-Z]:\\\\.*")
directory = log_directory.to_s
$dir_target = log_directory.to_s

searchfiles = "#{$dir_target}/**/#{sanitize_file_choice}"
Dir.glob(searchfiles).each do |search_file|
	sanitized_file = search_file+'.sanitized'
	sanitized_file = File.open(sanitized_file, 'w')
	File.open(search_file).each do |lines|
		search_file_line = lines.to_s
		regex_csv_data.each do|row|
			sanitized_regex = Regexp.new(row[1].to_s)
			replacement_string = row[2].to_s
			begin
				search_file_line = search_file_line.gsub(sanitized_regex, replacement_string)
			rescue
				puts search_file_line
			end
		end
			sanitized_file.puts(search_file_line)
	end
	sanitized_file.close
end

zipfile_name = File.join($dir_target, "sanitized_log.zip")

#sanitized_files = "#{$dir_target}/**/*.sanitized"
#Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
#	sanitized_files = "#{$dir_target}/**/*.sanitized"
#	Dir.glob(sanitized_files).each do |add_to_zip_files|
#	puts File.dirname(add_to_zip_files)
    # Two arguments:
    # - The name of the file as it will appear in the archive
    # - The original file, including the path to find it
#   zipfile.add(add_to_zip_files, add_to_zip_files.to_s)
#  end
#end

message = "Log sanitization completed.  Log Names are #{sanitize_file_choice}.sanitized"
sanitization_choices = ["Sanitization Complete "]
sanitization_choice = show_options(message,sanitization_choices,nil,"sanitization complete")