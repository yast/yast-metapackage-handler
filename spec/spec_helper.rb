# Copyright (c) [2020] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

SRC_PATH = File.expand_path("../src", __dir__)
DATA_PATH = File.expand_path("data", __dir__)
TEST_PATH = File.expand_path(__dir__)
ENV["Y2DIR"] = SRC_PATH


# Ensure the tests runs with english locales
ENV["LC_ALL"] = "en_US.UTF-8"
ENV["LANG"] = "en_US.UTF-8"

# load it early, so other stuffs are not ignored
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
  end

  # track all ruby files under src
  SimpleCov.track_files("#{SRC_PATH}/**/*.rb")

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

require "yast"
require "yast/rspec"

# configure RSpec
RSpec.configure do |c|
  c.extend Yast::I18n # available in context/describe
  c.include Yast::I18n
  c.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
