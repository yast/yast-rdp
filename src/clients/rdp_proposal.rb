# encoding: utf-8

# File:        clients/rdp_proposal.ycp
# Package:     Network configuration
# Summary:     Proposal for Remote Administration
# Authors:     Arvin Schnell <arvin@suse.de>
#		Michal Svec <msvec@suse.cz>
#		David Reveman <davidr@novell.com>
module Yast
  class RdpProposalClient < Client
    def main
      Yast.import "UI"

      textdomain "rdp"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("RDP proposal started")
      Builtins.y2milestone("Arguments: %1", WFM.Args)

      Yast.import "RDP"
      Yast.import "Wizard"
      Yast.import "PackagesProposal"
      Yast.import "ServicesProposal"
      Yast.import "SuSEFirewallProposal"
      Yast.include self, "rdp/dialogs.rb"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # create a textual proposal
      if @func == "MakeProposal"
        @proposal = ""
        @warning = nil
        @warning_level = nil
        @force_reset = Ops.get_boolean(@param, "force_reset", false)

        if @force_reset
          RDP.Reset
        else
          RDP.Propose
        end
        if RDP.open_fw_port
            SuSEFirewallProposal.OpenServiceOnNonDialUpInterfaces("service:xrdp",["3389"])
            SuSEFirewallProposal.SetChangedByUser(true)
        end
	if RDP.allow_administration
          PackagesProposal.AddResolvables('xrdp',:package,['xrdp'])
          ServicesProposal.enable_service("xrdp")
        else
          PackagesProposal.RemoveResolvables('xrdp',:package,['xrdp'])
          ServicesProposal.disable_service("xrdp")
        end
        @ret = { "raw_proposal" => [RDP.Summary] }
      # run the module
      elsif @func == "AskUser"
        # single dialog, no need to Export/Import

        Wizard.CreateDialog
        Wizard.SetDesktopIcon("remote")
        @result = RemoteMainDialog()
        UI.CloseDialog

        Builtins.y2debug("result=%1", @result)
        @ret = { "workflow_sequence" => @result }
      # create titles
      elsif @func == "Description"
        @ret = {
          # RichText label
          "rich_text_title" => _("RDP Remote Administration"),
          # Menu label
          "menu_title"      => _("RDP &Remote Administration"),
          "id"              => "admin_stuff"
        }
      # write the proposal
      elsif @func == "Write"
        RDP.Write
      else
        Builtins.y2error("unknown function: %1", @func)
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("RDP proposal finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::RdpProposalClient.new.main
