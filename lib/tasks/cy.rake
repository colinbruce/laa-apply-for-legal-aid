desc 'Duplicate the en locales to cy and reverse all strings'
task cy: :environment do
  require_relative 'helpers/cy_helper.rb'
  CyHelper.new.run


end
