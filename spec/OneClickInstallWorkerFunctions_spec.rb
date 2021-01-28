#! /usr/bin/env rspec

# Copyright (c) [2021] SUSE LLC
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

Yast.import "OneClickInstallWorkerFunctions"

describe Yast::OneClickInstallWorkerFunctions do

  let(:urls) { %w[http://example.com/repo1 http://example.com/repo2 http://example.com/repo3] }

  describe "#DeDupe" do
    before do
      allow(Yast::Pkg).to receive(:SourceStartCache).and_return([1])
    end
    context "when receives repository that is not subscribed on" do
      it "does not filter the repository" do
        allow(Yast::Pkg).to receive(:SourceGeneralData).and_return({})
        allow(Yast::OneClickInstall).to receive(:GetRepositoryName).and_return("test-name")

        expect(subject.DeDupe(urls)).to contain_exactly(urls[0], urls[1], urls[2])
      end
    end

    context "when receives repository that is already subscribed on" do
      it "removes repository if it is duplicated by 'url'" do
        allow(Yast::Pkg).to receive(:SourceGeneralData).and_return("url" => urls[1])
        allow(Yast::OneClickInstall).to receive(:GetRepositoryName).and_return("test-name")

        expect(subject.DeDupe(urls)).to contain_exactly(urls[0], urls[2])
      end

      it "removes repository if it is duplicated by 'name'" do
        allow(Yast::Pkg).to receive(:SourceGeneralData).and_return({ "name" => "oss" }, {}, {})
        allow(Yast::OneClickInstall).to receive(:GetRepositoryName).and_return("oss")

        expect(subject.DeDupe(urls)).to contain_exactly(urls[1], urls[2])
      end

      it "removes repository if it is duplicated by 'alias'" do
        allow(Yast::Pkg).to receive(:SourceGeneralData).and_return({}, {}, "alias" => "oss")
        allow(Yast::OneClickInstall).to receive(:GetRepositoryName).and_return("oss")

        expect(subject.DeDupe(urls)).to contain_exactly(urls[0], urls[1])
      end
    end
  end

  describe '#AddRepositories' do
    before do
      allow(subject).to receive(:DeDupe).and_return(urls)
    end
    context "when metadata can be downloaded for all repositories" do
      before do
        allow(Yast::Pkg).to receive(:SourceRefreshNow).and_return(true)
      end
      it "successfully adds the repositories" do
        expect(subject.AddRepositories(urls)).to be true
      end
    end

    context "when metadata can NOT be downloaded" do
      context "for all repositories" do
        before do
          allow(Yast::Pkg).to receive(:SourceRefreshNow).and_return(false)
        end
        it "does NOT add all the repositories" do
          expect(subject.AddRepositories(urls)).to be false
        end
      end
      context "for at least one repository" do
        before do
          allow(Yast::Pkg).to receive(:SourceRefreshNow).and_return(false, true, true)
        end
        it "does NOT add all the repositories" do
          expect(subject.AddRepositories(urls)).to be false
        end
      end
    end
  end
end
