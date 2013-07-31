# encoding: utf-8

module Yast
  class OneClickInstallWorkerClient < Client
    def main
      Yast.import "UI"
      textdomain "oneclickinstall"

      Yast.import "OneClickInstall"
      Yast.import "OneClickInstallWorkerResponse"
      Yast.import "OneClickInstallWorkerFunctions"
      Yast.import "Popup"
      Yast.include self, "packager/inst_source_dialogs.rb"
      Yast.import "PackageCallbacks"
      Yast.import "SlideShow"
      Yast.import "SlideShowCallbacks"
      Yast.import "PackageInstallation"
      Yast.import "PackageSlideShow"
      Yast.import "SourceManager"
      Yast.import "Progress"
      Yast.import "Wizard"

      @args = WFM.Args

      @xmlFileName = Ops.get_string(@args, 0, "")

      return false if @xmlFileName == ""

      Wizard.CreateDialog
      Wizard.SetDesktopIcon("sw_single")
      Wizard.SetDialogTitle(_("1-Click Install"))

      #Load the xml communication from the user interface.
      OneClickInstall.FromXML(@xmlFileName)

      @rurls = OneClickInstall.GetRequiredRepositories
      @rnames = []
      Builtins.foreach(@rurls) do |url|
        @rnames = Builtins.add(@rnames, OneClickInstall.GetRepositoryName(url))
      end
      @rnames = [_("Repositories")] if Builtins.size(@rnames) == 0

      #xxx add better stage and title when not in string freeze.
      Progress.New(_("Perform Installation"), "", 2, @rnames, [], "")
      Progress.NextStage

      @success = true

      @success = OneClickInstallWorkerFunctions.AddRepositories(
        OneClickInstall.GetRequiredRepositories
      )

      if !@success
        OneClickInstallWorkerResponse.SetFailureStage("Adding Repositories")
        OneClickInstallWorkerResponse.SetErrorMessage(
          _(
            "An error occurred while attempting to subscribe to the required repositories. Review the yast2 logs for more information."
          )
        )
      end

      Progress.NextStage

      if @success
        SlideShow.SetLanguage(UI.GetLanguage(true))

        SlideShow.Setup(
          [
            {
              "name"        => "packages",
              "description" => _("Installing Packages..."),
              "value"       => Ops.divide(
                PackageSlideShow.total_size_to_install,
                1024
              ), # kilobytes
              "units"       => :kb
            }
          ]
        )
        SlideShow.ShowTable
        SlideShow.OpenDialog

        SlideShow.MoveToStage("packages")

        PackageInstallation.CommitPackages(0, 0)

        #Remove any removals
        if @success && OneClickInstall.HaveRemovalsToInstall
          @success = OneClickInstallWorkerFunctions.RemovePackages(
            OneClickInstall.GetRequiredRemoveSoftware
          )

          if !@success
            OneClickInstallWorkerResponse.SetFailureStage("Removing Packages")
            OneClickInstallWorkerResponse.SetErrorMessage(
              _(
                "An error occurred while attempting to remove the specified packages. Review the yast2 logs for more information."
              )
            )
          end
        end


        #if that was successful now try and install the patterns
        if @success && OneClickInstall.HavePatternsToInstall
          @success = OneClickInstallWorkerFunctions.InstallPatterns(
            OneClickInstall.GetRequiredPatterns
          )

          if !@success
            OneClickInstallWorkerResponse.SetFailureStage("Installing Patterns")
            OneClickInstallWorkerResponse.SetErrorMessage(
              _(
                "An error occurred while attempting to install the specified patterns. Review the yast2 logs for more information."
              )
            )
          end
        end


        #if that was successful now try and install the packages
        if @success && OneClickInstall.HavePackagesToInstall
          @success = OneClickInstallWorkerFunctions.InstallPackages(
            OneClickInstall.GetRequiredPackages
          )
          if !@success
            OneClickInstallWorkerResponse.SetFailureStage("Installing Packages")
            OneClickInstallWorkerResponse.SetErrorMessage(
              _(
                "An error occurred while attempting to install the specified packages. Review the yast2 logs for more information."
              )
            )
          end
        end

        SlideShow.CloseDialog
      end

      #If we don't want to remain subscribed, remove the repositories that were added for installation.
      if OneClickInstall.HaveRepositoriesToInstall &&
          !OneClickInstall.GetRemainSubscribed
        @success = OneClickInstallWorkerFunctions.RemoveAddedRepositories
        if !@success
          OneClickInstallWorkerResponse.SetFailureStage(
            "Removing temporarily installed repositories."
          )
          OneClickInstallWorkerResponse.SetErrorMessage(
            _(
              "An error occurred while attempting to unsubscribe from the repositories that were used to perform the installation. You can remove them manually in YaST > Software Repositories. Review the yast2 logs for more information."
            )
          )
        end
      end

      OneClickInstallWorkerResponse.SetSuccess(@success)

      if @success
        OneClickInstallWorkerResponse.SetFailureStage("No Failure")
        OneClickInstallWorkerResponse.SetErrorMessage(_("No error occurred."))
      end

      #Overwrite the information we were passed with our response back to the UI.
      OneClickInstallWorkerResponse.ToXML(@xmlFileName)

      UI.CloseDialog

      @success
    end
  end
end

Yast::OneClickInstallWorkerClient.new.main
