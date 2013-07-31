# encoding: utf-8

# Command line interface for One Click Install
module Yast
  class OneClickInstallCLIClient < Client
    def main
      textdomain "oneclickinstall"

      Yast.import "OneClickInstall"
      Yast.import "OneClickInstallWorkerFunctions"
      Yast.import "CommandLine"
      Yast.import "HTTP"
      Yast.import "FTP"

      @cmdline = {
        "help"     => _("One Click Install Command Line Installer"),
        "id"       => "OneClickInstall",
        "actions"  => {
          "prepareinstall" => {
            "help"    => _("Processes a YMP file, ready for installation"),
            "handler" => fun_ref(
              method(:PrepareInstallHandler),
              "boolean (map <string, string>)"
            )
          },
          "doinstall"      => {
            "help"    => _("Processes a YMP file, ready for installation"),
            "handler" => fun_ref(
              method(:DoInstallHandler),
              "boolean (map <string, string>)"
            )
          }
        },
        "options"  => {
          "url"              => {
            "help" => _("URL of .ymp file"),
            "type" => "string"
          },
          "targetfile"       => {
            "help" => _("File to put internal representation of YMP into"),
            "type" => "string"
          },
          "instructionsfile" => {
            "help" => _(
              "File containing internal representation of <b>One Click Install</b> instructions"
            ),
            "type" => "string"
          }
        },
        "mappings" => {
          "prepareinstall" => ["url", "targetfile"],
          "doinstall"      => ["instructionsfile"]
        }
      }

      @ret = CommandLine.Run(@cmdline)
      deep_copy(@ret)
    end

    def PrepareInstall(ympFile, tempFile)
      OneClickInstall.Load(ympFile)

      if !OneClickInstall.HaveAnythingToDo
        Builtins.y2error("Nothing to do specified in the YMP file")
        CommandLine.Print(_("Error: Nothing to do specified in the YMP file."))
        return false
      end

      if OneClickInstall.HaveRepositories
        CommandLine.Print(
          _("If you continue, the following repositories will be subscribed:")
        )
        Builtins.foreach(OneClickInstall.GetRequiredRepositories) do |repository|
          CommandLine.Print(Ops.add("\t* ", repository))
        end
      end


      if OneClickInstall.HaveSoftware
        CommandLine.Print(
          _(
            "If you continue, the following software packages will be installed:"
          )
        )
        Builtins.foreach(OneClickInstall.GetRequiredSoftware) do |software|
          CommandLine.Print(Ops.add("\t* ", software))
        end
      end

      OneClickInstall.ToXML(tempFile)
      true
    end

    def PrepareInstallHandler(options)
      options = deep_copy(options)
      #trick ncurses
      url = Ops.get(options, "url", "")
      tempFile = Ops.get(options, "targetfile", "")
      if Builtins.substring(url, 0, 1) != "/"
        url = OneClickInstallWorkerFunctions.GrabFile(url)
      end

      if url == nil
        Builtins.y2error(
          "Unable to retrieve YMP at %1",
          Ops.get(options, "url", "")
        )
        CommandLine.Print(
          Builtins.sformat(
            _("Unable to retrieve YMP at %1"),
            Ops.get(options, "url", "")
          )
        )
        return false
      end

      PrepareInstall(url, tempFile)
    end

    def DoInstall(xmlfile)
      OneClickInstall.FromXML(xmlfile)

      if OneClickInstall.HaveRepositoriesToInstall
        CommandLine.Print(_("Adding Repositories..."))
      end

      success = OneClickInstallWorkerFunctions.AddRepositories(
        OneClickInstall.GetRequiredRepositories
      )

      if !success
        Builtins.y2error("Unable to add repositories")
        CommandLine.Print(_("Error: Unable to add repositories"))
        return false
      end

      #Remove any removals
      if OneClickInstall.HaveRemovalsToInstall
        CommandLine.Print(_("Removing Packages..."))
        success = OneClickInstallWorkerFunctions.RemovePackages(
          OneClickInstall.GetRequiredRemoveSoftware
        )
      end
      if !success
        Builtins.y2error("Unable to remove packages")
        CommandLine.Print(_("Error: Unable to remove packages"))
        return false
      end

      #if that was successful now try and install the patterns
      if OneClickInstall.HavePatternsToInstall
        CommandLine.Print(_("Installing Patterns..."))
        success = OneClickInstallWorkerFunctions.InstallPatterns(
          OneClickInstall.GetRequiredPatterns
        )
      end
      if !success
        Builtins.y2error("Unable to install patterns")
        CommandLine.Print(_("Error: Unable to install patterns"))
        return false
      end

      #if that was successful now try and install the packages
      if OneClickInstall.HavePackagesToInstall
        CommandLine.Print(_("Installing Packages..."))
        success = OneClickInstallWorkerFunctions.InstallPackages(
          OneClickInstall.GetRequiredPackages
        )
      end
      if !success
        Builtins.y2error("Unable to install packages")
        CommandLine.Print(_("Error: Unable to install packages"))
        return false
      end

      #If we don't want to remain subscribed, remove the repositories that were added for installation.
      if OneClickInstall.HaveRepositoriesToInstall &&
          !OneClickInstall.GetRemainSubscribed
        success = OneClickInstallWorkerFunctions.RemoveAddedRepositories
      end
      if !success
        Builtins.y2error("Unable to remove temporarily added repositories")
        CommandLine.Print(
          _("Warning: Unable to remove temporarily added repositories.")
        )
        return false
      end
      CommandLine.Print(_("Finished"))
      true
    end

    def AmRoot
      out = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), "/usr/bin/id --user")
      )
      Ops.get_string(out, "stdout", "") == "0\n"
    end

    def DoInstallHandler(options)
      options = deep_copy(options)
      if AmRoot()
        return DoInstall(Ops.get(options, "instructionsfile", ""))
      else
        Builtins.y2error("Cannot install software as limited user")
        CommandLine.Print(_("Error: Must be root"))
        return false
      end
    end
  end
end

Yast::OneClickInstallCLIClient.new.main
