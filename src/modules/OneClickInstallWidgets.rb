# encoding: utf-8

require "yast"

module Yast
  class OneClickInstallWidgetsClass < Module
    def main
      Yast.import "UI"
      textdomain "oneclickinstall"

      Yast.import "Label"
      Yast.import "HTML"
      Yast.import "Product"

      @SPACER = "                                                                    "

      @repositoriesUI = VBox(
        VWeight(2, Heading(_("Additional Software Repositories"))),
        VWeight(
          10,
          MultiSelectionBox(
            Id(:repositoriesCheckList),
            Opt(:notify),
            _("Select the software repositories you wish to subscribe to:"),
            [@SPACER]
          )
        ),
        VWeight(
          1,
          CheckBox(
            Id(:remain),
            _("Remain subscribed to these repositories after installation"),
            true
          )
        ),
        VWeight(5, RichText(Id(:descrLabel), ""))
      )


      @softwareUI = VBox(
        VWeight(2, Heading(_("Software to Be Installed"))),
        VWeight(
          10,
          MultiSelectionBox(
            Id(:softwareCheckList),
            Opt(:notify),
            _("Select the software components you wish to install:"),
            [@SPACER]
          )
        ),
        VWeight(5, RichText(Id(:packageDescrLabel), ""))
      )

      @removeUI = VBox(
        VWeight(2, Heading(_("Software to Be Removed"))),
        VWeight(
          10,
          MultiSelectionBox(
            Id(:removeCheckList),
            Opt(:notify),
            _("Select the software components you wish to remove:"),
            [@SPACER]
          )
        ),
        VWeight(5, RichText(Id(:removeDescrLabel), ""))
      )

      @nothing = VBox(
        Heading(_("Installation not possible")),
        RichText(
          _("The install link or file you opened does not contain instructions for %s.") % Product.name
        )
      )



      @perform = HBox(
        HSpacing(1),
        VBox(
          VSpacing(0.2),
          Heading(_("Software is being installed.")),
          VSpacing(0.2)
        ),
        HSpacing(1)
      )

      @canRead = false
    end

    def StringListToTermList(strList, checked)
      strList = deep_copy(strList)
      items = []
      Builtins.foreach(strList) do |str|
        items = Builtins.add(items, Item(Id(str), str, checked))
      end
      deep_copy(items)
    end


    #This wouldn't be necessary if regexpsub wasn't so retarded.
    def NewLinesToRichText(original)
      result = ""
      lines = Builtins.splitstring(original, "\n")
      Builtins.foreach(lines) do |line|
        result = Ops.add(Ops.add(result, line), HTML.Newline)
      end
      result
    end

    def GetRepositorySelectionUI
      deep_copy(@repositoriesUI)
    end

    def PopulateRepositorySelectionUIDescription(description)
      UI.ChangeWidget(
        :descrLabel,
        :Value,
        Ops.add(
          Ops.add(
            Ops.add(
              "<body>",
              HTML.Heading(_("Repository Description:"))
            ),
            NewLinesToRichText(description)
          ),
          "</body>"
        )
      )

      nil
    end

    def PopulateRepositorySelectionUI(description, requiredRepos, nonRequiredRepos, remainSubscribed)
      requiredRepos = deep_copy(requiredRepos)
      nonRequiredRepos = deep_copy(nonRequiredRepos)
      UI.ChangeWidget(Id(:remain), :Value, remainSubscribed)
      newRepositoryNames = Convert.convert(
        Builtins.merge(
          StringListToTermList(requiredRepos, true),
          StringListToTermList(nonRequiredRepos, false)
        ),
        :from => "list",
        :to   => "list <term>"
      )
      UI.ChangeWidget(Id(:repositoriesCheckList), :Items, newRepositoryNames)
      PopulateRepositorySelectionUIDescription(description)

      nil
    end

    def GetCurrentlySelectedRepository
      Convert.to_string(
        UI.QueryWidget(Id(:repositoriesCheckList), :CurrentItem)
      )
    end

    def GetRepositorySelectionItems
      Convert.convert(
        UI.QueryWidget(Id(:repositoriesCheckList), :SelectedItems),
        :from => "any",
        :to   => "list <string>"
      )
    end

    def GetRepositoryRemainSubscribed
      Convert.to_boolean(UI.QueryWidget(Id(:remain), :Value))
    end

    def GetSoftwareSelectionUI
      deep_copy(@softwareUI)
    end

    def PopulateSoftwareSelectionUIDescription(description)
      UI.ChangeWidget(
        :packageDescrLabel,
        :Value,
        Ops.add(
          Ops.add(
            Ops.add(
              "<body>",
              HTML.Heading(_("Package Description:"))
            ),
            NewLinesToRichText(description)
          ),
          "</body>"
        )
      )

      nil
    end

    def PopulateSoftwareSelectionUI(description, requiredSW, nonRequiredSW)
      requiredSW = deep_copy(requiredSW)
      nonRequiredSW = deep_copy(nonRequiredSW)
      newSoftwareNames = Convert.convert(
        Builtins.merge(
          StringListToTermList(requiredSW, true),
          StringListToTermList(nonRequiredSW, false)
        ),
        :from => "list",
        :to   => "list <term>"
      )
      UI.ChangeWidget(Id(:softwareCheckList), :Items, newSoftwareNames)
      PopulateSoftwareSelectionUIDescription(description)

      nil
    end

    def GetCurrentlySelectedSoftware
      Convert.to_string(UI.QueryWidget(Id(:softwareCheckList), :CurrentItem))
    end

    def GetSoftwareSelectionItems
      Convert.convert(
        UI.QueryWidget(Id(:softwareCheckList), :SelectedItems),
        :from => "any",
        :to   => "list <string>"
      )
    end

    def GetSoftwareRemovalSelectionUI
      deep_copy(@removeUI)
    end

    def PopulateSoftwareRemovalSelectionUIDescription(description)
      UI.ChangeWidget(
        :removeDescrLabel,
        :Value,
        Ops.add(
          Ops.add(
            Ops.add(
              "<body>",
              HTML.Heading(_("Package Description:"))
            ),
            NewLinesToRichText(description)
          ),
          "</body>"
        )
      )

      nil
    end

    def PopulateSoftwareRemovalSelectionUI(description, requiredRemovals, nonRequiredRemovals)
      requiredRemovals = deep_copy(requiredRemovals)
      nonRequiredRemovals = deep_copy(nonRequiredRemovals)
      newSoftwareNames = Convert.convert(
        Builtins.merge(
          StringListToTermList(requiredRemovals, true),
          StringListToTermList(nonRequiredRemovals, false)
        ),
        :from => "list",
        :to   => "list <term>"
      )
      UI.ChangeWidget(Id(:removeCheckList), :Items, newSoftwareNames)

      PopulateSoftwareRemovalSelectionUIDescription(description)

      nil
    end

    def GetCurrentlySelectedRemoval
      Convert.to_string(UI.QueryWidget(Id(:removeCheckList), :CurrentItem))
    end


    def GetSoftwareRemovalSelectionItems
      Convert.convert(
        UI.QueryWidget(Id(:removeCheckList), :SelectedItems),
        :from => "any",
        :to   => "list <string>"
      )
    end

    def GetIncompatibleYMPUI
      deep_copy(@nothing)
    end
    def GetCanRead
      @canRead
    end

    def ConfirmUI
      UI.OpenDialog(
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(0.2),
            VBox(
              Left(Heading(Label.WarningMsg)),
              HCenter(
                Label(
                  _(
                    "Have you reviewed the changes that will be made to your system?\nMalicious packages could damage your system.\n"
                  )
                )
              ),
              VSpacing(0.4),
              Left(
                CheckBox(
                  Id(:iCanRead),
                  Opt(:notify, :immediate),
                  _("Do not ask me again")
                )
              ),
              VSpacing(0.2)
            ),
            HBox(
              HStretch(),
              HWeight(1, PushButton(Id(:yes), Opt(:key_F10), Label.YesButton)),
              HSpacing(2),
              HWeight(
                1,
                PushButton(Id(:no), Opt(:default, :key_F9), Label.NoButton)
              ),
              HStretch()
            ),
            VSpacing(0.2)
          ),
          HSpacing(1)
        )
      )
      ret = UI.UserInput
      while ret != :yes && ret != :no
        if ret == :iCanRead
          UI.ChangeWidget(
            :no,
            :Enabled,
            !Convert.to_boolean(UI.QueryWidget(:iCanRead, :Value))
          )
        end
        ret = UI.UserInput
      end
      @canRead = Convert.to_boolean(UI.QueryWidget(:iCanRead, :Value))
      UI.CloseDialog
      ret == :yes
    end

    def getProposalString(repositories, packages, removals, remainSubscribed)
      repositories = deep_copy(repositories)
      packages = deep_copy(packages)
      removals = deep_copy(removals)
      repoStr = HTML.List(repositories)
      packageStr = HTML.List(packages)
      removeStr = HTML.ColoredList(removals, "red")

      tempOrPerm = ""
      if !remainSubscribed
        tempOrPerm = _(
          "These repositories will only be added during installation. You will not remain subscribed."
        )
      else
        tempOrPerm = _(
          "You will remain subscribed to these repositories after installation."
        )
      end

      summaryStr = Ops.add(
        "<body>",
        HTML.Colorize(
          _(
            "If you continue, the following changes will be made to your system:"
          ),
          "red"
        )
      )

      #Put remove message at top, incase people try to push it off the bottom of the warning by adding lots of packages.
      if Ops.greater_than(Builtins.size(removals), 0)
        summaryStr = Ops.add(
          Ops.add(
            summaryStr,
            HTML.Heading(HTML.Colorize(_("Software to be removed:"), "red"))
          ),
          removeStr
        )
      end

      if Ops.greater_than(Builtins.size(repositories), 0)
        summaryStr = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  summaryStr,
                  HTML.Heading(_("Repositories to be added:"))
                ),
                repoStr
              ),
              HTML.Bold(_("Note:"))
            ),
            HTML.Newline
          ),
          HTML.List([tempOrPerm])
        )
      end

      if Ops.greater_than(Builtins.size(packages), 0)
        summaryStr = Ops.add(
          Ops.add(summaryStr, HTML.Heading(_("Software to be installed:"))),
          packageStr
        )
      end


      summaryStr = Ops.add(summaryStr, "</body>")
      summaryStr
    end


    def GetProposalUI
      HBox(
        VBox(
          VSpacing(0.5),
          Left(Heading(_("Proposal"))),
          VWeight(5, RichText(Id(:summary), "")),
          HBox(Right(PushButton(Id(:alterProposal), _("Customize"))))
        )
      )
    end

    def PopulateProposalUI(repositories, packages, removals, remainSubscribed)
      repositories = deep_copy(repositories)
      packages = deep_copy(packages)
      removals = deep_copy(removals)
      proposal = getProposalString(
        repositories,
        packages,
        removals,
        remainSubscribed
      )
      UI.ChangeWidget(Id(:summary), :Value, proposal)

      nil
    end

    def GetDescriptionUI
      HBox(
        VBox(
          VSpacing(0.5),
          ReplacePoint(Id(:head), Empty()),
          VSpacing(0.5),
          VWeight(5, RichText(Id(:splashMessage), ""))
        )
      )
    end

    def PopulateDescriptionUI(name, summary, description)
      UI.ReplaceWidget(
        Id(:head),
        VBox(Left(Heading(name)), Left(Label(summary)))
      )
      UI.ChangeWidget(
        Id(:splashMessage),
        :Value,
        Ops.add(
          Ops.add(
            "<body>",
            HTML.Para(NewLinesToRichText(description))
          ),
          "</body>"
        )
      )

      nil
    end

    def GetPerformingUI
      deep_copy(@perform)
    end

    def GetResultUI
      HBox(
        HSpacing(1),
        VBox(VSpacing(0.1), RichText(Id(:resultLabel), ""), VSpacing(0.2)),
        HSpacing(1)
      )
    end

    def PopulateResultUI(success, failedRepositories, failedPatterns, failedPackages, failureStage, errorMessage, note)
      failedRepositories = deep_copy(failedRepositories)
      failedPatterns = deep_copy(failedPatterns)
      failedPackages = deep_copy(failedPackages)
      statusStr = Ops.add(
        "<body>",
        HTML.Heading(_("Software installation"))
      )

      if success
        if Builtins.size(failedRepositories) == 0 &&
            Builtins.size(failedPatterns) == 0 &&
            Builtins.size(failedPackages) == 0
          statusStr = Ops.add(
            statusStr,
            HTML.Para(_("Installation was successful"))
          )
        else
          statusStr = Ops.add(
            statusStr,
            HTML.Para(_("Installation was only partially successful."))
          )
        end
      else
        statusStr = Ops.add(
          statusStr,
          HTML.Para(
            Ops.add(
              _(
                "The installation has failed. For more information, see the log file at <tt>/var/log/YaST2/y2log</tt>. Failure stage was: "
              ) + " ",
              failureStage
            )
          )
        )
        statusStr = Ops.add(
          Ops.add(statusStr, HTML.Heading(_("Error Message"))),
          HTML.Para(errorMessage)
        )
      end

      if Ops.greater_than(Builtins.size(failedRepositories), 0)
        statusStr = Ops.add(
          Ops.add(
            statusStr,
            HTML.Heading(_("The following repositories could not be added"))
          ),
          HTML.List(failedRepositories)
        )
      end

      if Ops.greater_than(Builtins.size(failedPatterns), 0)
        statusStr = Ops.add(
          Ops.add(
            statusStr,
            HTML.Heading(_("The following patterns could not be installed"))
          ),
          HTML.List(failedPatterns)
        )
      end

      if Ops.greater_than(Builtins.size(failedPackages), 0)
        statusStr = Ops.add(
          Ops.add(
            statusStr,
            HTML.Heading(_("The following packages could not be installed"))
          ),
          HTML.List(failedPackages)
        )
      end

      statusStr = Ops.add(statusStr, HTML.Para(note))

      statusStr = Ops.add(statusStr, "</body>")

      UI.ChangeWidget(:resultLabel, :Value, statusStr)

      nil
    end

    publish :function => :GetRepositorySelectionUI, :type => "term ()"
    publish :function => :PopulateRepositorySelectionUIDescription, :type => "void (string)"
    publish :function => :PopulateRepositorySelectionUI, :type => "void (string, list <string>, list <string>, boolean)"
    publish :function => :GetCurrentlySelectedRepository, :type => "string ()"
    publish :function => :GetRepositorySelectionItems, :type => "list <string> ()"
    publish :function => :GetRepositoryRemainSubscribed, :type => "boolean ()"
    publish :function => :GetSoftwareSelectionUI, :type => "term ()"
    publish :function => :PopulateSoftwareSelectionUIDescription, :type => "void (string)"
    publish :function => :PopulateSoftwareSelectionUI, :type => "void (string, list <string>, list <string>)"
    publish :function => :GetCurrentlySelectedSoftware, :type => "string ()"
    publish :function => :GetSoftwareSelectionItems, :type => "list <string> ()"
    publish :function => :GetSoftwareRemovalSelectionUI, :type => "term ()"
    publish :function => :PopulateSoftwareRemovalSelectionUIDescription, :type => "void (string)"
    publish :function => :PopulateSoftwareRemovalSelectionUI, :type => "void (string, list <string>, list <string>)"
    publish :function => :GetCurrentlySelectedRemoval, :type => "string ()"
    publish :function => :GetSoftwareRemovalSelectionItems, :type => "list <string> ()"
    publish :function => :GetIncompatibleYMPUI, :type => "term ()"
    publish :function => :GetCanRead, :type => "boolean ()"
    publish :function => :ConfirmUI, :type => "boolean ()"
    publish :function => :GetProposalUI, :type => "term ()"
    publish :function => :PopulateProposalUI, :type => "void (list <string>, list <string>, list <string>, boolean)"
    publish :function => :GetDescriptionUI, :type => "term ()"
    publish :function => :PopulateDescriptionUI, :type => "void (string, string, string)"
    publish :function => :GetPerformingUI, :type => "term ()"
    publish :function => :GetResultUI, :type => "term ()"
    publish :function => :PopulateResultUI, :type => "void (boolean, list <string>, list <string>, list <string>, string, string, string)"
  end

  OneClickInstallWidgets = OneClickInstallWidgetsClass.new
  OneClickInstallWidgets.main
end
