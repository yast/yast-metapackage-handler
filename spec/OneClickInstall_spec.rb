#! /usr/bin/env rspec

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

require_relative "spec_helper"

require "yast"

Yast.import "OneClickInstall"

describe Yast::OneClickInstall do
  let(:filepath) { File.join(DATA_PATH, "vim.ymp") }
  let(:output) { "" }

  describe "#xml_from_file" do
    context "ymp file parsed" do
      it "parses the XML file" do
        doc = subject.xml_from_file(filepath)
        expect(doc).to be_instance_of(REXML::Document)
        doc.write(output)
        expect(output).to include("vim")
      end
    end
  end

  describe "#xpath_match" do
    context "matching node" do
      it "returns and array of elements, matching xpath" do
        doc = REXML::Document.new(File.read(filepath))
        expect(subject.xpath_match(doc, "metapackage//url").first.text).to eq("http://download.opensuse.org/tumbleweed/repo/oss/")
      end
    end
  end

  describe "#SetRequiredRepository" do
    context "set repository to recommended" do
      it "Ensures that the repository with the specified URL is selected for addition" do
        url = "http://download.opensuse.org/tumbleweed/repo/oss/"
        subject.instance_variable_set(:@repositories, { url => { "name" => "vim" , "recommended" => "false" }})
        subject.SetRequiredRepository(url)
        repos = subject.instance_variable_get(:@repositories)
        expect(repos[url]["name"]).to eql("vim")
        expect(repos[url]["recommended"]).to eql("true")
      end
    end
  end
end
