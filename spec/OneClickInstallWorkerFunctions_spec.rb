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

  describe '#RemoveAddedRepositories' do
    context "when metadata cached on disk is removed" do
      before do
        allow(Yast::Pkg).to receive(:SourceDelete).and_return(true)
      end
      it "removes added repositories" do
        expect(subject.RemoveAddedRepositories).to be true
      end
    end
    context "when metadata cached on disk is NOT removed" do
      before do
        allow(Yast::Pkg).to receive(:SourceDelete).and_return(false)
      end
      it "does not remove added repositories" do
        expect(subject.RemoveAddedRepositories).to be false
      end
    end
  end

  describe '#InstallPackages' do
    before do
      allow(Yast::Pkg).to receive(:ResolvableInstallRepo).and_return(true)
    end
    context "when package depedencies are resolved" do
      before do
        allow(Yast::Pkg).to receive(:PkgSolve).and_return(true)
      end
      it "installs packages" do
        expect(subject.InstallPackages("vim")).to be true
      end
    end
    context "when package depedencies are not resolved" do
      before do
        allow(Yast::Pkg).to receive(:PkgSolve).and_return(false)
      end
      it "installs packages if package selection is accepted" do
        allow(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:accept)
        expect(subject.InstallPackages("vim")).to be true
      end
      it "does not install packages if package selection is not accepted" do
        allow(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:cancel)
        expect(subject.InstallPackages("vim")).to be false
      end
    end
  end

  describe '#InstallPatterns' do
    context "when pattern depedencies are resolved" do
      before do
        allow(Yast::Pkg).to receive(:PkgSolve).and_return(true)
      end
      it "installs pattern" do
        expect(subject.InstallPatterns("gnome")).to be true
      end
    end
    context "when pattern depedencies are not resolved" do
      before do
        allow(Yast::Pkg).to receive(:PkgSolve).and_return(false)
      end
      it "installs pattern if package selection is accepted" do
        allow(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:accept)
        expect(subject.InstallPatterns("gnome")).to be true
      end
      it "does not install pattern if package selection is not accepted" do
        allow(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:cancel)
        expect(subject.InstallPatterns("gnome")).to be false
      end
    end
  end

  describe '#RemovePackages' do
    context "when package depedensies are resolved" do
      before do
        allow(Yast::Pkg).to receive(:PkgSolve).and_return(true)
      end
      it "removes installed package" do
        expect(subject.RemovePackages("vim")).to be true
      end
    end
    context "when package depedencies are not resolved" do
      before do
        allow(Yast::Pkg).to receive(:PkgSolve).and_return(false)
      end
      it "removes installed packages if package selection is accepted" do
        allow(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:accept)
        expect(subject.RemovePackages("vim")).to be true 
      end
      it "does not remove installed packages if package selection is not accepted" do
        allow(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:cancel)
        expect(subject.RemovePackages("vim")).to be false 
      end
    end
  end

end
