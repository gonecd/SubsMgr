require "spec_helper"

describe "bundle install with deprecated features" do
	before :each do
		in_app_root
	end

	%w().each do |deprecated|

		it "reports that #{deprecated} is deprecated" do
			gemfile <<-G
				#{deprecated}
			G

			bundle :install
			out.should =~ /'#{deprecated}' has been removed/
			out.should =~ /See the README for more information/
		end

	end


	%w().each do |deprecated|

		it "reports that :#{deprecated} is deprecated" do
			gemfile <<-G
				gem "rack", :#{deprecated} => true
			G

			bundle :install
			out.should =~ /Please replace :#{deprecated}|The :#{deprecated} option is no longer supported/
		end

	end

end