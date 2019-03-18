# encoding: utf-8

# File:	remote/dialogs.ycp
# Module:	Network configuration
# Summary:	Dialog for Remote RDP Administration
# Authors:	Arvin Schnell <arvin@suse.de>
#		David Reveman <davidr@novell.com>
module Yast
  module RdpDialogsInclude
    def initialize_rdp_dialogs(include_target)
      Yast.import "UI"

      textdomain "rdp"

      Yast.import "Label"
      Yast.import "RDP"
      Yast.import "Wizard"
    end

    # Remote administration dialog
    # @return dialog result
    def RemoteMainDialog
      # Dialog contents
      contents = HBox(
        HStretch(),
        VBox(
          Frame(
            _("Settings"),
            VBox(
                Left(CheckBox(Id(:enable), _('Enable RDP (Remote Desktop Protocol) Service'), RDP.allow_administration)),
                Left(CheckBox(Id(:open_fw_port), _('Open Port in Firewall'), RDP.open_fw_port))
            )
          )
        ),
        HStretch()
      )

      help = _("<p><b><big>Remote Administration via RDP</big></b></p>\n" +
              "<p>Remote Desktop Protocol (RDP) is a secure remote administration protocol " +
              "running on TCP port 3389.</p>" +
              "<p>If the feature is enabled, you will be able to login to this computer\n" +
              "remotely via an RDP client such as Windows Remote Desktop Viewer.\n")
      Wizard.SetContentsButtons(
        _("Remote Administration via RDP"),
        contents,
        help,
        Label.BackButton,
        Label.FinishButton
      )

      ret = nil
      event = nil
      begin
        event = UI.WaitForEvent
        ret = Ops.get(event, "ID")

        if ret == :abort
          break
        elsif ret == :help
          Wizard.ShowHelp(help)
        elsif ret == :cancel
          break
        end
      end until ret == :next || ret == :back

      if ret == :next
        RDP.allow_administration = UI.QueryWidget(Id(:enable), :Value)
        RDP.open_fw_port = UI.QueryWidget(Id(:open_fw_port), :Value)
      end

      Convert.to_symbol(ret)
    end
  end
end
