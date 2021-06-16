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
  let(:urls) { ["http://download.opensuse.org/tumbleweed/repo/oss/",
                "http://download.opensuse.org/tumbleweed/repo/non-oss/"] }
  let!(:repositories) { subject.instance_variable_set(:@repositories, 
                                                     { urls[0] => { "name" => "oss" , "recommended" => "true" },
                                                       urls[1] => { "name" => "non-oss" , "recommended" => "false" }}) }
  let!(:software) { subject.instance_variable_set(:@software, 
                                                 { "vim" => { "recommended" => "true" , "action" => "install" , "type" => "package" },
                                                   "tftp" => { "recommended" => "false" , "action" => "install" , "type" => "package" },
                                                   "x11" => { "recommended" => "true" , "action" => "install" , "type" => "pattern" },
                                                   "sap_server" => { "recommended" => "true" , "action" => "remove" , "type" => "pattern" }}) }

  describe "#xml_from_file" do
    it "parses the XML file" do
      doc = subject.xml_from_file(filepath)
      expect(doc).to be_instance_of(REXML::Document)
      doc.write(output)
      expect(output).to include("vim")
    end
  end

  describe "#xpath_match" do
    it "returns and array of elements, matching xpath" do
      doc = REXML::Document.new(File.read(filepath))
      expect(subject.xpath_match(doc, "metapackage//url").first.text).to eq(urls[0])
    end
  end

  describe "#SetRequiredRepository" do
    it "Ensures that the repository with the specified URL is selected for addition" do
      subject.instance_variable_set(:@repositories, { urls[0] => { "name" => "oss" , "recommended" => "false" }})
      subject.SetRequiredRepository(urls[0])
      repos = subject.instance_variable_get(:@repositories)
      expect(repos[urls[0]]).to match_array( "name" => "oss" , "recommended" => "true" )
    end
  end

  describe "#SetNonRequiredRepository" do
    it "Ensures that the repository with the specified URL is not selected for addition" do
      subject.instance_variable_set(:@repositories, { urls[1] => { "name" => "non-oss" , "recommended" => "true" }})
      subject.SetNonRequiredRepository(urls[1])
      repos = subject.instance_variable_get(:@repositories)
      expect(repos[urls[1]]["name"]).to eql("non-oss")
      expect(repos[urls[1]]["recommended"]).to eql("false")
    end
  end

  describe "#SetRequiredRepositories" do
    it "Ensures that the repositories with the specified URL are selected for addition" do
      subject.SetRequiredRepositories(urls)
      repos = subject.instance_variable_get(:@repositories)
      expect(repos[urls[0]]).to match_array( "name" => "oss" , "recommended" => "true" )
      expect(repos[urls[1]]).to match_array( "name" => "non-oss" , "recommended" => "true" )
    end
  end
  
  describe "#GetRequiredRepositories" do
    it "Returns a list of the URLs of the repositories currently selected for addition" do
      repos = subject.GetRequiredRepositories
      expect(repos).to match_array([urls[0]]) 
    end
  end

  describe "#GetNonRequiredRepositories" do
    it "Returns a list of the URLs of the repositories currently not selected for addition" do
      repos = subject.GetNonRequiredRepositories
      expect(repos).to match_array(urls[1])
    end
  end

  describe "#GetRequiredSoftware" do
    it "Returns a list of the names of the software currently selected for installation" do
      software_to_install = subject.GetRequiredSoftware
      expect(software_to_install).to match_array(["vim" , "x11"])
    end
  end

  describe "#GetRequiredRemoveSoftware" do
    it "Returns a list of the names of the software currently selected for removal" do
      software_to_remove = subject.GetRequiredRemoveSoftware
      expect(software_to_remove).to match_array(["sap_server"])
    end
  end

  describe "#GetRequiredPackages" do
    it "Returns a list of the names of the packages currently selected for installation" do
      packages_to_install = subject.GetRequiredPackages
      expect(packages_to_install).to match_array(["vim"])
    end
  end

  describe "#GetRequiredPatterns" do
    it "Returns a list of the names of the patterns currently selected for installation" do
      patterns_to_install = subject.GetRequiredPatterns
      expect(patterns_to_install).to match_array(["x11"])
    end
  end

  describe "#HaveAnyRecommended" do
    it "Returns boolean, depending on the existence of any recommended repositories or software" do
      any_recommended = subject.HaveAnyRecommended
      expect(any_recommended).to be true
    end
  end  

  describe "#makeXMLFriendly" do
    it "converts map structure (eg. @repositories) to a list of maps with a key element" do
      flattened = subject.makeXMLFriendly(software)
      expect(flattened).to match_array([
        {"recommended"=>"true", "action"=>"remove", "type"=>"pattern", "key"=>"sap_server"},
        {"recommended"=>"false", "action"=>"install", "type"=>"package", "key"=>"tftp"},
        {"recommended"=>"true", "action"=>"install", "type"=>"package", "key"=>"vim"},
        {"recommended"=>"true", "action"=>"install", "type"=>"pattern", "key"=>"x11"}])
    end
  end

  describe "#fromXMLFriendly" do
    it "converts back from makeXMLFriendly to original structure" do
      flattened = [
        {"recommended"=>"true", "action"=>"remove", "type"=>"pattern", "key"=>"sap_server"},
        {"recommended"=>"false", "action"=>"install", "type"=>"package", "key"=>"tftp"},
        {"recommended"=>"true", "action"=>"install", "type"=>"package", "key"=>"vim"},
        {"recommended"=>"true", "action"=>"install", "type"=>"pattern", "key"=>"x11"}]
      unflattened = subject.fromXMLFriendly(flattened)
      expect(unflattened).to match_array(software)
    end
  end

  describe "#ToXML" do
    it "serializes to XML file, according to OneClickInstall data structure" do
      output_file = File.join(DATA_PATH, "serialized_result.xml")
      subject.ToXML(output_file)
      result = File.read(output_file)
      expected_file = File.join(DATA_PATH, "serialized_expected.xml")
      expected = File.read(expected_file)
      expect(result).to eql(expected)
      File.delete(output_file)
    end
  end

  describe "#FromXML" do
    it "deserializes according to OneClickInstall data structure to XML" do
      filename = File.join(DATA_PATH, "to_deserialize.xml")
      subject.FromXML(filename) 
      expect(subject.instance_variable_get(:@software)).to match_array({"zdoom"=>{"action"=>"install", "recommended"=>"false", "type"=>"package"}})
      expect(subject.instance_variable_get(:@repositories)).to match_array({"https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/"=>{"name"=>"packman", "recommended"=>"false"}})
      expect(subject.instance_variable_get(:@remainSubscribed)).to be true
      expect(subject.instance_variable_get(:@summary)).to be_empty
      expect(subject.instance_variable_get(:@description)).to be_empty
      expect(subject.instance_variable_get(:@name)).to be_empty
    end
  end

  describe "#Load" do
    context "when loading YMP file" do
      it "loads the Metapackage data from the YML file supplied for further processing" do
        subject.Load(filepath)
        expect(subject.instance_variable_get(:@repositories)[urls[0]]).to include("name"=>"openSUSE:Factory",
                                                                                  "summary"=>"The next openSUSE distribution",
                                                                                  "recommended"=>"true") 
        expect(subject.instance_variable_get(:@software)["vim"]).to include("summary"=>"Vi IMproved",
                                                                            "recommended"=>"true",
                                                                            "action"=>"install",
                                                                            "type"=>"package") 
        expect(subject.instance_variable_get(:@name)).to eql("vim")
        expect(subject.instance_variable_get(:@remainSubscribed)).to be true
        expect(subject.instance_variable_get(:@description)).to include("Vim (Vi IMproved) is an almost compatible version of the UNIX editor")
      end
    end
  end
end
