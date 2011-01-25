# Include hook code here
require File.dirname(__FILE__) + '/lib/has_tree'

ActiveRecord::Base.send(:include, HasTree)
