# convert.rb
# Ben Garvey
# ben@bengarvey.com
#
# Description:  Converts a CSV file to json for use in a D3 treemap.
# Writing this for the philadelphia transparent budget project
#

require 'csv'
require 'json'

class BudgetItem

  attr_accessor :name, :size, :children

  def initialize
  end

end

class BudgetPrinter

  def initialize
  end

  def printOut(b)
    count = 0

  File.open('data/all.json', 'w') do |json|  
  # use "\n" for two lines of text  
  #json.puts bp.printOut(budget).to_s

    json.puts "{\n"
    json.puts "\t\"name\" : " + b.name.to_json + ",\n"
   
    puts("COUNT LEVEL 1: " + b.children.count.to_s + " " + b.name.to_s)
    json.puts "\t\"children\" : [\n"
    b.children.each do |kid|
      json.puts "\t{\t\"name\" : #{kid.name.to_json},\n\t\t\"children\" : [\n"
      puts("COUNT LEVEL 2: " + kid.children.count.to_s + " " + kid.name.to_s)
      i=0
      kid.children.each do |k|
          # Getting a bug where empty nodes are showing up.  Hack to fix that
          if kid.name != k.name
            json.puts "\t\t{\n\t\t\t\"name\" : #{k.name.to_json},\n\t\t\t\"children\" : [\n"
            k.children.each do |l|
              json.print "\t\t\t\t{\"name\" : #{l.name.to_json},\t\t\"value\" : #{l.size.to_f.to_json}}"
              
              # Since we're writing directly to the file now, we can't chomp off the comma.
              if (k.children.last != l)
                json.puts ",\n" 
              else
                json.puts "\n"
              end
                
              #puts("Added " + l.name.to_s)
              if count % 1000 == 0
                puts("Record " + count.to_s + " finished. " + ( (count.to_f/200000)*100).to_s + "% complete")
              end
              count += 1
            end
          #json = json.chomp(",\n") + "\n"
          json.print "\t\t\t]\n\t\t}"
          
          # Since we're writing directly to the file now, we can't just chomp off the comma
          if kid.children.size  == i+2
            json.puts("\n")
          else
            json.puts(",\n")
          end
          i += 1
         end
        end
        #json = json.chomp(",\n")
        json.print  "\n\t]\n\t}"
        # Since we're writing directly to the file now, we can't just chomp off the comma
        if b.children.last != kid
          json.puts(",\n")
        else
          json.puts("\n")
        end
     end
     #json = json.chomp(",\n") + "\n"
     json.puts "\n]\n}\n"
    end
  end
end

csv = ""

first 	= 2;
second 	= 4;
budget = BudgetItem.new
budget.name = "Philadelpha Budget 2012"
budget.children = Array.new
budget.size = ""

#limit  = 189500
limit   = 300000
#limit  = 189550
count = 0

# Load in csv file
#CSV.foreach("data/philadelphia-2012-budget.csv") do |row|
CSV.foreach("data/full_table.csv") do |row|

  if (count < limit)

  # First load in all the budget data and names
  b = BudgetItem.new
  b.size = row[12].to_s.gsub(/\,/,"")
 
  # Some have parenthesis.  Change them to negative numbers
  if b.size[0] == "("
    b.size[0] = "-"
    b.size[-1] = ""
  end

  if b.size == ""
    b.size = 0
  end

  if (b.size.to_f > 0)

  #b.name = row[8].to_s + " " + row[9].to_s + " " + row[7].to_s + " " + row[5].to_s + " " + row[6].to_s
  b.name = row[7].to_s + " " + row[8].to_s + " " + row[9].to_s + " " + row[10].to_s + " " + row[11].to_s + " " + row[12].to_s
  
  primary   = row[1]
  secondary = row[3]

  # Now we're consolidating all detailed values
  b.name = secondary;

  # We are now consolidating the salaries in order to make the treemap more readable and speed thing up
  #if (secondary == "Personal Services (salary & Other Pay)") 
  #  b.name = "salary"
  #end


  foundprimary = false
  foundsecondary = false
  parent = ""

  
  if (b.size != "")

  # Now see if we have a place for it yet
  budget.children.each do |kid|
    if kid.name == primary
  
      foundprimary = true
      parent = kid

      # We found the correct parent, now check for this item's children
      kid.children.each do |k|
        if k.name == secondary
            # add them
  
            if b.name == k.name
              # Find salary and increment instead of adding a new one
              k.children.each do |c|
                  temp = c.size.to_f + b.size.to_f
                  c.size = temp.to_f
              end               
            else 
              k.children.push(b)
            end

            foundsecondary = true
        end
      end
    end
  end

  # If not found, add it to the main
  if !foundprimary
    p = BudgetItem.new
    s = BudgetItem.new
    p.name = primary
    s.name = secondary
    p.children = Array.new
    s.children = Array.new
    budget.children.push(p)
    p.children.push(s)
    p.children.push(p)

    s.children.push(b)
  end

  # if we never found this secondary, add it to the parent we found
  if foundprimary && !foundsecondary
    s = BudgetItem.new
    s.name = secondary
    s.children = Array.new
    parent.children.push(s)
    s.children.push(b)
  end

  end

  foundprimary = false
  foundsecondary = false

  end

  end

  count += 1

end

bp = BudgetPrinter.new
#puts(bp.printOut(budget).to_s)

bp.printOut(budget)

