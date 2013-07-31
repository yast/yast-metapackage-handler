# encoding: utf-8

# Holds functions both the CLI and GUI installers require.
require "yast"

module Yast
  class OneClickInstallWorkerFunctionsClass < Module
    def main
      Yast.import "Pkg"

      textdomain "oneclickinstall"

      Yast.import "HTTP"
      Yast.import "FTP"
      Yast.import "OneClickInstall"
      Yast.import "OneClickInstallWorkerResponse"
      Yast.import "Popup"
      Yast.include self, "packager/inst_source_dialogs.rb"
      Yast.import "PackageCallbacks"
      Yast.import "SourceManager"
      Yast.import "Progress"
      Yast.import "PackageSlideShow"
      Yast.import "SlideShow"
      Yast.import "PackagesUI"

      Yast.import "CommandLine"

      @SEPARATOR = "/"

      @GUI = true
      @deduped_repos = []

      @sourceids = []
    end

    def setGUI(value)
      @GUI = value

      nil
    end

    def print(value)
      CommandLine.Print(value) if !@GUI

      nil
    end

    def FuzzyMatch(one, two)
      chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
      Builtins.tolower(Builtins.filterchars(one, chars)) ==
        Builtins.tolower(Builtins.filterchars(two, chars))
    end
    #* Check whether this repository is already subscribed
    #
    def DeDupe(url_list)
      url_list = deep_copy(url_list)
      # read trusted GPG keys
      Pkg.TargetInitialize("/")

      sources = Pkg.SourceStartCache(true)

      deduped = []

      Builtins.foreach(url_list) do |new|
        dupeFound = false
        Builtins.foreach(sources) do |srcid|
          repoData = Pkg.SourceGeneralData(srcid)
          if Ops.get_string(repoData, "url", "") == new
            #keep a note of this repo, we still want to prefer packages from it
            #to those in other repositories
            @deduped_repos = Builtins.add(@deduped_repos, srcid)
            dupeFound = true
            raise Break
          end
          if FuzzyMatch(
              Ops.get_string(repoData, "name", ""),
              OneClickInstall.GetRepositoryName(new)
            )
            @deduped_repos = Builtins.add(@deduped_repos, srcid)
            dupeFound = true
            raise Break
          end
          if FuzzyMatch(
              Ops.get_string(repoData, "alias", ""),
              OneClickInstall.GetRepositoryName(new)
            )
            @deduped_repos = Builtins.add(@deduped_repos, srcid)
            dupeFound = true
            raise Break
          end
        end
        deduped = Builtins.add(deduped, new) if !dupeFound
      end

      deep_copy(deduped)
    end
    #* Subscribe to all the specified repositories
    #* return true if all catalogues were added successfully, false otherwise.
    #
    def AddRepositories(repositories)
      repositories = deep_copy(repositories)
      addRepoSuccess = true
      print(_("Loading Package Management"))

      dedupedRepos = DeDupe(repositories)
      Builtins.foreach(dedupedRepos) do |new_url|
        print(Builtins.sformat(_("Adding repository %1"), new_url))
        again = true
        while again
          repoData = {
            "enabled"     => true,
            "autorefresh" => true,
            "name"        => OneClickInstall.GetRepositoryName(new_url),
            "alias"       => OneClickInstall.GetRepositoryName(new_url),
            "base_urls"   => [new_url]
          }
          srcid = Pkg.RepositoryAdd(repoData)
          success = Pkg.SourceRefreshNow(srcid)
          if !success
            if Popup.YesNo(
                Ops.add(
                  Ops.add(
                    Ops.add(
                      _(
                        "An error occurred while initializing the software repository."
                      ) + "\n" +
                        _("Details:") + "\n",
                      Pkg.LastError
                    ),
                    "\n"
                  ),
                  _("Try again?")
                )
              )
              new_url = editUrl(new_url)
            else
              OneClickInstallWorkerResponse.AddFailedRepository(new_url)
              again = false
              addRepoSuccess = false
              next false
            end
          else
            @sourceids = Builtins.add(@sourceids, srcid)
            # save the repository
            Pkg.SourceSaveAll
            again = false
          end
        end
        #Should be safe, definition ignores call when in command line mode or no progress is visible.
        Progress.NextStage
      end
      addRepoSuccess
    end


    def InitSlideShow(description)
      PackageSlideShow.InitPkgData(true) # force reinitialization

      # TODO FIXME: doesn't work properly for removed packages
      stages = [
        {
          "name"        => "packages",
          "description" => description,
          "value"       => Ops.divide(
            PackageSlideShow.total_size_to_install,
            1024
          ), # kilobytes
          "units"       => :kb
        }
      ]

      SlideShow.Setup(stages)

      SlideShow.MoveToStage("packages")

      nil
    end

    #* Install all the specified packages
    #* return true if all installations were successful, false otherwise
    #
    def InstallPackages(packages)
      packages = deep_copy(packages)
      Pkg.SourceLoad
      Builtins.foreach(packages) do |name|
        print(Builtins.sformat(_("Marking package %1 for installation"), name))
        #Prefer packages from repositories specified in the YMP
        inYmpRepos = false
        Builtins.foreach(
          Convert.convert(
            Builtins.merge(@sourceids, @deduped_repos),
            :from => "list",
            :to   => "list <integer>"
          )
        ) do |id|
          Builtins.y2debug("Looking for %1 in %2", name, id)
          inYmpRepos = Pkg.ResolvableInstallRepo(name, :package, id)
          if inYmpRepos
            Builtins.y2debug("Found %1 in %2", name, id)
            raise Break
          else
            Builtins.y2debug("Didn't find %1 in %2", name, id)
          end
        end
        if !inYmpRepos
          Builtins.y2debug("Didn't find %1 At ALL in any YMP repos", name)
        end
        #If we didn't find it in the repos specified in the YMP try any repo.
        if !inYmpRepos && !Pkg.PkgInstall(name)
          print(
            Builtins.sformat(
              _("Warning: package %1 could not be installed."),
              name
            )
          )
          OneClickInstallWorkerResponse.AddFailedPackage(name) if @GUI
        end
      end

      state = true
      Pkg.TargetInit("/", false)
      if Pkg.PkgSolve(true)
        # initialize slideshow data (package counters)
        InitSlideShow(_("Installing Packages..."))

        print(_("Performing Installation..."))
        state = !Ops.less_than(Ops.get_integer(Pkg.PkgCommit(0), 0, -1), 0) #xxx no callback for resolve failures
      else
        result = PackagesUI.RunPackageSelector({ "mode" => :summaryMode })
        if result == :accept
          # initialize slideshow data (package counters)
          InitSlideShow(_("Installing Packages..."))

          state = !Ops.less_than(Ops.get_integer(Pkg.PkgCommit(0), 0, -1), 0)
        else
          state = false
        end
      end

      state
    end

    #* Install all the specified patterns
    #* return true if all installations were successful, false otherwise
    #
    def InstallPatterns(patterns)
      patterns = deep_copy(patterns)
      Pkg.TargetInit("/", false)
      Builtins.foreach(patterns) do |name|
        if !Pkg.ResolvableInstall(name, :pattern)
          print(
            Builtins.sformat(
              _("Warning: pattern %1 could not be installed."),
              name
            )
          )
          OneClickInstallWorkerResponse.AddFailedPattern(name) if @GUI
        end
      end

      state = true

      if Pkg.PkgSolve(true)
        # initialize slideshow data (package counters)
        InitSlideShow(_("Installing Patterns..."))

        state = !Ops.less_than(Ops.get_integer(Pkg.PkgCommit(0), 0, -1), 0) #xxx no callback for resolve failures
      else
        result = PackagesUI.RunPackageSelector({ "mode" => :summaryMode })
        if result == :accept
          state = !Ops.less_than(Ops.get_integer(Pkg.PkgCommit(0), 0, -1), 0)
        else
          state = false
        end
      end

      state
    end

    #* Remove all the specified packages
    #* return true if all installations were successful, false otherwise
    #
    def RemovePackages(packages)
      packages = deep_copy(packages)
      Pkg.TargetInit("/", false)
      result = true
      Builtins.foreach(packages) { |name| result = Pkg.PkgDelete(name) }

      state = true
      if Pkg.PkgSolve(true)
        # initialize slideshow data (package counters)
        InitSlideShow(_("Removing Packages..."))

        state = !Ops.less_than(Ops.get_integer(Pkg.PkgCommit(0), 0, -1), 0) #xxx no callback for resolve failures
      else
        result2 = PackagesUI.RunPackageSelector({ "mode" => :summaryMode })
        if result2 == :accept
          state = !Ops.less_than(Ops.get_integer(Pkg.PkgCommit(0), 0, -1), 0)
        else
          state = false
        end
      end

      state
    end

    def RemoveAddedRepositories
      success = true
      Builtins.foreach(@sourceids) do |srcid|
        success = success && Pkg.SourceDelete(srcid)
      end 

      Pkg.SourceSaveAll
      success
    end

    def GrabFile(url)
      newUrl = Ops.add(
        Ops.add(Convert.to_string(SCR.Read(path(".target.tmpdir"))), @SEPARATOR),
        "metapackage.xml"
      )
      if Builtins.substring(url, 0, 4) == "http" ||
          Builtins.substring(url, 0, 4) == "file"
        response = HTTP.Get(url, newUrl)
        if Ops.greater_or_equal(Ops.get_integer(response, "code", 400), 400)
          return nil
        end
        return newUrl
      elsif Builtins.substring(url, 0, 3) == "ftp"
        FTP.Get(url, newUrl)
        return newUrl
      else
        Builtins.y2error(
          "Argument is neither local absolute path nor an HTTP or FTP URL. Bye."
        )
        return nil
      end
      nil
    end

    publish :function => :setGUI, :type => "void (boolean)"
    publish :function => :FuzzyMatch, :type => "boolean (string, string)"
    publish :function => :DeDupe, :type => "list <string> (list <string>)"
    publish :function => :AddRepositories, :type => "boolean (list <string>)"
    publish :function => :InstallPackages, :type => "boolean (list <string>)"
    publish :function => :InstallPatterns, :type => "boolean (list <string>)"
    publish :function => :RemovePackages, :type => "boolean (list <string>)"
    publish :function => :RemoveAddedRepositories, :type => "boolean ()"
    publish :function => :GrabFile, :type => "string (string)"
  end

  OneClickInstallWorkerFunctions = OneClickInstallWorkerFunctionsClass.new
  OneClickInstallWorkerFunctions.main
end
