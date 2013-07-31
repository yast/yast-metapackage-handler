# encoding: utf-8

# User Interface for the One Click Install Feature.
module Yast
  class OneClickInstallUIClient < Client
    def main
      Yast.import "UI"
      textdomain "oneclickinstall"

      Yast.import "OneClickInstall"
      Yast.import "OneClickInstallWidgets"
      Yast.import "OneClickInstallWorkerResponse"
      Yast.import "OneClickInstallWorkerFunctions"
      Yast.import "Wizard"
      Yast.import "Popup"
      Yast.import "Label"
      Yast.import "HTTP"
      Yast.import "FTP"
      Yast.import "UserSettings"

      @args = WFM.Args

      @SU_CMD = "xdg-su -c"
      @SU_CMD_FAILURE_CODE = 3
      @FALLBACK_SU_CMD = "xdg_menu_su"
      @SEPARATOR = "/"

      @metaPackageUrl = "http://opensuse.org/repos.ymp"

      if Ops.greater_than(Builtins.size(@args), 0)
        @metaPackageUrl = Ops.get_string(@args, 0, @metaPackageUrl)
      end


      if Builtins.substring(@metaPackageUrl, 0, 1) != "/"
        @metaPackageUrl = OneClickInstallWorkerFunctions.GrabFile(
          @metaPackageUrl
        )
        return false if @metaPackageUrl == nil
      end

      OneClickInstall.Load(@metaPackageUrl)

      # <region name="String constants"> *

      @HELP1 = _("This wizard will install software on your computer.")
      @HELP2 = _(
        "See <tt>http://en.opensuse.org/One_Click_Install</tt> for more information."
      )

      # <region name="Define the UI components"> *

      @HELP_TEXT = Ops.add(
        Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                "<h3>" +
                  _("Select the software components you wish to install:") + "</h3>" + "<p>",
                @HELP1
              ),
              "</p>"
            ),
            "<p>"
          ),
          @HELP2
        ),
        "</p>"
      )
      #xxx without this the width of the items in the multi-selection-box seems to be broken.
      @SPACER = "                                                                    "
      # </region> *
      # <region name="Setup the Wizard Steps"> *

      @installation_steps_simple = []
      @installation_widgets_simple = []

      @installation_steps_simple = [
        { "id" => "splash", "label" => _("Software Description") },
        { "id" => "confirm", "label" => _("Installation Settings") },
        { "id" => "perform", "label" => _("Perform Installation") },
        { "id" => "result", "label" => _("Results") }
      ]

      @installation_widgets_simple = [
        {
          "id"     => "splash",
          "widget" => OneClickInstallWidgets.GetDescriptionUI
        },
        { "id" => "confirm", "widget" => OneClickInstallWidgets.GetProposalUI },
        {
          "id"     => "perform",
          "widget" => OneClickInstallWidgets.GetPerformingUI
        },
        { "id" => "result", "widget" => OneClickInstallWidgets.GetResultUI }
      ]

      @installation_steps = deep_copy(@installation_steps_simple)
      @installation_widgets = deep_copy(@installation_widgets_simple)

      @installation_steps_advanced = []
      @installation_widgets_advanced = []

      if OneClickInstall.HaveRepositories && OneClickInstall.HaveSoftware &&
          !OneClickInstall.HaveRemovals
        @installation_steps_advanced = [
          { "id" => "repositoriesUI", "label" => _("Repositories") },
          { "id" => "softwareUI", "label" => _("Software") },
          { "id" => "confirm", "label" => _("Installation Settings") },
          { "id" => "perform", "label" => _("Perform Installation") },
          { "id" => "result", "label" => _("Results") }
        ]

        @installation_widgets_advanced = [
          {
            "id"     => "repositoriesUI",
            "widget" => OneClickInstallWidgets.GetRepositorySelectionUI
          },
          {
            "id"     => "softwareUI",
            "widget" => OneClickInstallWidgets.GetSoftwareSelectionUI
          },
          {
            "id"     => "confirm",
            "widget" => OneClickInstallWidgets.GetProposalUI
          },
          {
            "id"     => "perform",
            "widget" => OneClickInstallWidgets.GetPerformingUI
          },
          { "id" => "result", "widget" => OneClickInstallWidgets.GetResultUI }
        ]
      elsif OneClickInstall.HaveRepositories && OneClickInstall.HaveSoftware &&
          OneClickInstall.HaveRemovals
        @installation_steps_advanced = [
          { "id" => "repositoriesUI", "label" => _("Repositories") },
          { "id" => "softwareUI", "label" => _("Software") },
          { "id" => "removeUI", "label" => _("Removals") },
          { "id" => "confirm", "label" => _("Installation Settings") },
          { "id" => "perform", "label" => _("Perform Installation") },
          { "id" => "result", "label" => _("Results") }
        ]
        @installation_widgets_advanced = [
          {
            "id"     => "repositoriesUI",
            "widget" => OneClickInstallWidgets.GetRepositorySelectionUI
          },
          {
            "id"     => "softwareUI",
            "widget" => OneClickInstallWidgets.GetSoftwareSelectionUI
          },
          {
            "id"     => "removeUI",
            "widget" => OneClickInstallWidgets.GetSoftwareRemovalSelectionUI
          },
          {
            "id"     => "confirm",
            "widget" => OneClickInstallWidgets.GetProposalUI
          },
          {
            "id"     => "perform",
            "widget" => OneClickInstallWidgets.GetPerformingUI
          },
          { "id" => "result", "widget" => OneClickInstallWidgets.GetResultUI }
        ]
      elsif OneClickInstall.HaveRepositories && !OneClickInstall.HaveSoftware
        @installation_steps_advanced = [
          { "id" => "repositoriesUI", "label" => _("Repositories") },
          { "id" => "confirm", "label" => _("Installation Settings") },
          { "id" => "perform", "label" => _("Perform Installation") },
          { "id" => "result", "label" => _("Results") }
        ]
        @installation_widgets_advanced = [
          {
            "id"     => "repositoriesUI",
            "widget" => OneClickInstallWidgets.GetRepositorySelectionUI
          },
          {
            "id"     => "confirm",
            "widget" => OneClickInstallWidgets.GetProposalUI
          },
          {
            "id"     => "perform",
            "widget" => OneClickInstallWidgets.GetPerformingUI
          },
          { "id" => "result", "widget" => OneClickInstallWidgets.GetResultUI }
        ]
      elsif !OneClickInstall.HaveRepositories && OneClickInstall.HaveSoftware &&
          !OneClickInstall.HaveRemovals
        @installation_steps_advanced = [
          { "id" => "softwareUI", "label" => _("Software") },
          { "id" => "confirm", "label" => _("Installation Settings") },
          { "id" => "perform", "label" => _("Perform Installation") },
          { "id" => "result", "label" => _("Results") }
        ]
        @installation_widgets_advanced = [
          {
            "id"     => "softwareUI",
            "widget" => OneClickInstallWidgets.GetSoftwareSelectionUI
          },
          {
            "id"     => "confirm",
            "widget" => OneClickInstallWidgets.GetProposalUI
          },
          {
            "id"     => "perform",
            "widget" => OneClickInstallWidgets.GetPerformingUI
          },
          { "id" => "result", "widget" => OneClickInstallWidgets.GetResultUI }
        ]
      elsif !OneClickInstall.HaveRepositories && OneClickInstall.HaveSoftware &&
          OneClickInstall.HaveRemovals
        @installation_steps_advanced = [
          { "id" => "softwareUI", "label" => _("Software") },
          { "id" => "removeUI", "label" => _("Removals") },
          { "id" => "confirm", "label" => _("Installation Settings") },
          { "id" => "perform", "label" => _("Perform Installation") },
          { "id" => "result", "label" => _("Results") }
        ]
        @installation_widgets_advanced = [
          {
            "id"     => "softwareUI",
            "widget" => OneClickInstallWidgets.GetSoftwareSelectionUI
          },
          {
            "id"     => "removeUI",
            "widget" => OneClickInstallWidgets.GetSoftwareRemovalSelectionUI
          },
          {
            "id"     => "confirm",
            "widget" => OneClickInstallWidgets.GetProposalUI
          },
          {
            "id"     => "perform",
            "widget" => OneClickInstallWidgets.GetPerformingUI
          },
          { "id" => "result", "widget" => OneClickInstallWidgets.GetResultUI }
        ]
      else
        @installation_steps_advanced = [
          { "id" => "nothing", "label" => _("Nothing to do.") }
        ]
        @installation_widgets_advanced = [
          {
            "id"     => "nothing",
            "widget" => OneClickInstallWidgets.GetIncompatibleYMPUI
          }
        ]
      end

      #Don't display simple mode if not appropriate
      if !OneClickInstall.HaveAnythingToDo ||
          !OneClickInstall.HaveBundleDescription ||
          !OneClickInstall.HaveAnyRecommended
        @installation_steps = deep_copy(@installation_steps_advanced)
        @installation_widgets = deep_copy(@installation_widgets_advanced)
      elsif OneClickInstall.HaveBundleDescription
        #Add the splash to the advanced steps too. Requested.
        @installation_steps_advanced = Builtins.prepend(
          @installation_steps_advanced,
          { "id" => "splash", "label" => _("Software Description") }
        )
        @installation_widgets_advanced = Builtins.prepend(
          @installation_widgets_advanced,
          {
            "id"     => "splash",
            "widget" => OneClickInstallWidgets.GetDescriptionUI
          }
        )
      end
      Wizard.OpenNextBackStepsDialog
      SetupWizard()


      @current_step = 0

      @done = false

      # </region> *
      # <region name="event loop">*
      show_step(0)
      while !@done
        @button = nil
        begin
          @button = Convert.to_symbol(UI.UserInput)
          handle_input(@button)
        end until @button != :repositoriesCheckList && @button != :softwareCheckList
        break if @button == :abort || @button == :cancel

        if @button == :alterProposal
          SwitchToAdvancedMode()
          next
        end

        if @button == :next || @button == :back
          if events_before_stage_change(@current_step, @button)
            if @button == :next &&
                Ops.less_than(
                  Ops.add(@current_step, 1),
                  Builtins.size(@installation_steps)
                )
              @current_step = Ops.add(@current_step, 1)
            end

            if @button == :back && Ops.greater_than(@current_step, 0)
              @current_step = Ops.subtract(@current_step, 1)
            end

            show_step(@current_step)

            events_after_stage_change(@current_step, @button)

            @done = true if @button == :finish
          end
        end

        @done = true if @button == :finish
      end
      UI.CloseDialog 
      # </region> *

      nil
    end

    def confirmCommit
      if UserSettings.GetBooleanValue("OneClickInstallUI", "CanRead")
        return true
      end
      confirmed = OneClickInstallWidgets.ConfirmUI
      UserSettings.SetValue(
        "OneClickInstallUI",
        "CanRead",
        OneClickInstallWidgets.GetCanRead
      )
      confirmed
    end


    # </region> *

    # <region name="wizardy bits"> *


    def is_performing(no)
      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      current_id == "perform"
    end

    def is_confirming(no)
      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      current_id == "confirm"
    end

    def is_selecting_repositories(no)
      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      current_id == "repositoriesUI"
    end

    def is_selecting_software(no)
      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      current_id == "softwareUI"
    end

    def is_selecting_removals(no)
      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      current_id == "removeUI"
    end

    def is_done(no)
      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      current_id == "result"
    end

    def is_viewing_splash(no)
      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      current_id == "splash"
    end

    def SetupWizard
      UI.WizardCommand(term(:DeleteSteps))
      Wizard.SetDesktopIcon("sw_single") # #329644
      Wizard.SetDialogTitle(_("1-Click Install"))
      Wizard.SetContents(
        Builtins.sformat(_("%1 Installation"), OneClickInstall.GetName),
        Empty(),
        @HELP_TEXT,
        true,
        true
      )

      UI.WizardCommand(term(:AddStepHeading, _("Installation Steps")))

      Builtins.foreach(@installation_steps) do |step|
        UI.WizardCommand(
          term(
            :AddStep,
            Ops.get_string(step, "label", ""),
            Ops.get_string(step, "id", "")
          )
        )
      end

      nil
    end

    # </region> *

    # <region name="wire up the wizard UI to the OCI module">*
    def StringListToTermList(strList, checked)
      strList = deep_copy(strList)
      items = []
      Builtins.foreach(strList) do |str|
        items = Builtins.add(items, Item(Id(str), str, checked))
      end
      deep_copy(items)
    end

    def show_step(no)
      if no == 0
        Wizard.DisableBackButton
      else
        Wizard.EnableBackButton
      end

      current_id = Ops.get_string(Ops.get(@installation_steps, no), "id", "")
      if is_done(no)
        Wizard.SetNextButton(:finish, Label.FinishButton)
        Wizard.DisableAbortButton
        Wizard.DisableBackButton
      end

      UI.ReplaceWidget(
        Id(:contents),
        Ops.get_term(Ops.get(@installation_widgets, no, {}), "widget") do
          OneClickInstallWidgets.GetIncompatibleYMPUI
        end
      )
      Wizard.SetTitleIcon("yast-software")
      Wizard.SetDialogTitle(_("1-Click Install"))

      UI.WizardCommand(term(:SetCurrentStep, current_id))
      if is_viewing_splash(no)
        OneClickInstallWidgets.PopulateDescriptionUI(
          OneClickInstall.GetName,
          OneClickInstall.GetSummary,
          OneClickInstall.GetDescription
        )
      end

      if is_selecting_repositories(no)
        firstUrl = Ops.get(OneClickInstall.GetRequiredRepositories, 0, "")
        OneClickInstallWidgets.PopulateRepositorySelectionUI(
          OneClickInstall.GetRepositoryDescription(firstUrl),
          OneClickInstall.GetRequiredRepositories,
          OneClickInstall.GetNonRequiredRepositories,
          OneClickInstall.GetRemainSubscribed
        )
      end
      if is_selecting_software(no)
        firstname = Ops.get(OneClickInstall.GetRequiredSoftware, 0, "")
        OneClickInstallWidgets.PopulateSoftwareSelectionUI(
          OneClickInstall.GetSoftwareDescription(firstname),
          OneClickInstall.GetRequiredSoftware,
          OneClickInstall.GetNonRequiredSoftware
        )
      end
      if is_selecting_removals(no)
        firstname = Ops.get(OneClickInstall.GetRequiredRemoveSoftware, 0, "")
        OneClickInstallWidgets.PopulateSoftwareRemovalSelectionUI(
          OneClickInstall.GetSoftwareDescription(firstname),
          OneClickInstall.GetRequiredRemoveSoftware,
          OneClickInstall.GetNonRequiredRemoveSoftware
        )
      end

      nil
    end


    def SwitchToAdvancedMode
      @installation_steps = deep_copy(@installation_steps_advanced)
      @installation_widgets = deep_copy(@installation_widgets_advanced)
      SetupWizard()
      if OneClickInstall.HaveBundleDescription
        @current_step = 1
      else
        @current_step = 0
      end
      show_step(@current_step)

      nil
    end

    def events_before_stage_change(step, button)
      if is_selecting_repositories(step)
        OneClickInstall.SetRemainSubscribed(
          OneClickInstallWidgets.GetRepositoryRemainSubscribed
        )
      end
      return confirmCommit if is_confirming(step) && button == :next
      true
    end


    def events_after_stage_change(step, button)
      if is_confirming(step)
        OneClickInstallWidgets.PopulateProposalUI(
          Builtins.maplist(OneClickInstall.GetRequiredRepositories) do |s|
            Ops.add(
              Ops.add(Ops.add(s, " ("), OneClickInstall.GetRepositoryName(s)),
              ")"
            )
          end,
          OneClickInstall.GetRequiredSoftware,
          OneClickInstall.GetRequiredRemoveSoftware,
          OneClickInstall.GetRemainSubscribed
        )
      end
      if is_performing(step)
        Wizard.DisableBackButton
        Wizard.DisableNextButton

        #I don't think we need to include timestamp/random seed here as yast seems to generate its own for tmpdir.
        communication_file = Ops.add(
          Ops.add(
            Convert.to_string(SCR.Read(path(".target.tmpdir"))),
            @SEPARATOR
          ),
          "oneclickinstall.xml"
        )
        OneClickInstall.ToXML(communication_file)

        #Check if we are already root #305354
        out = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), "/usr/bin/id --user")
        )
        root = Ops.get_string(out, "stdout", "") == "0\n"
        if root
          WFM.call("OneClickInstallWorker", [communication_file])
        else
          ret = Convert.to_integer(
            SCR.Execute(
              path(".target.bash"),
              Ops.add(
                Ops.add(
                  Ops.add(@SU_CMD, " '/sbin/yast2 OneClickInstallWorker "),
                  communication_file
                ),
                "'"
              )
            )
          )
          if ret == @SU_CMD_FAILURE_CODE
            ret = Convert.to_integer(
              SCR.Execute(
                path(".target.bash"),
                Ops.add(
                  Ops.add(
                    Ops.add(
                      @FALLBACK_SU_CMD,
                      " '/sbin/yast2 OneClickInstallWorker "
                    ),
                    communication_file
                  ),
                  "'"
                )
              )
            )
          end
        end

        #Load the response.
        OneClickInstallWorkerResponse.FromXML(communication_file)



        @current_step = Ops.add(@current_step, 1)
        Wizard.EnableNextButton

        show_step(@current_step)

        OneClickInstallWidgets.PopulateResultUI(
          OneClickInstallWorkerResponse.GetSuccess,
          OneClickInstallWorkerResponse.GetFailedRepositories,
          OneClickInstallWorkerResponse.GetFailedPatterns,
          OneClickInstallWorkerResponse.GetFailedPackages,
          OneClickInstallWorkerResponse.GetFailureStage,
          OneClickInstallWorkerResponse.GetErrorMessage,
          OneClickInstallWorkerResponse.GetNote
        )
      end

      nil
    end
    def handle_input(button)
      if button == :repositoriesCheckList
        #Get the description of this one.
        OneClickInstallWidgets.PopulateRepositorySelectionUIDescription(
          OneClickInstall.GetRepositoryDescription(
            OneClickInstallWidgets.GetCurrentlySelectedRepository
          )
        )
        #Set all repositories to non-required

        #Set the currently selected repositories back to subscribed.
        OneClickInstall.SetRequiredRepositories(
          OneClickInstallWidgets.GetRepositorySelectionItems
        )
      end

      if button == :softwareCheckList
        OneClickInstallWidgets.PopulateSoftwareSelectionUIDescription(
          OneClickInstall.GetSoftwareDescription(
            OneClickInstallWidgets.GetCurrentlySelectedSoftware
          )
        )
        OneClickInstall.SetRequiredSoftwares(
          OneClickInstallWidgets.GetSoftwareSelectionItems
        )
      end

      if button == :removeCheckList
        OneClickInstallWidgets.PopulateSoftwareRemovalSelectionUIDescription(
          OneClickInstall.GetSoftwareDescription(
            OneClickInstallWidgets.GetCurrentlySelectedRemoval
          )
        )
        #Set the currently selected removals back to remove.
        OneClickInstall.SetRequiredSoftwares(
          OneClickInstallWidgets.GetSoftwareRemovalSelectionItems
        )
      end

      nil
    end
  end
end

Yast::OneClickInstallUIClient.new.main
