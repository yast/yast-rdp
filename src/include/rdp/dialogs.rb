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
      Yast.import "CWMFirewallInterfaces"

      Yast.include include_target, "network/routines.rb"
    end

    # Remote administration dialog
    # @return dialog result
    def RemoteMainDialog
      # Ramote Administration dialog caption
      caption = _("Remote Administration")

      allow_buttons = RadioButtonGroup(
        VBox(
          # RadioButton label
          Left(
            RadioButton(Id(:allow), _("&Allow Remote Administration"), false)
          ),
          # RadioButton label
          Left(
            RadioButton(
              Id(:disallow),
              _("&Do Not Allow Remote Administration"),
              false
            )
          )
        )
      )

      firewall_widget = CWMFirewallInterfaces.CreateOpenFirewallWidget(
        { "services" => ["service:xrdp"], "display_details" => true }
      )
      firewall_layout = Ops.get_term(firewall_widget, "custom_widget", VBox())
      firewall_help = Ops.get_string(firewall_widget, "help", "")

      help = Ops.add(
        Builtins.sformat(
          _(
            "<p><b><big>Remote Administration Settings</big></b></p>\n" +
              "<p>If this feature is enabled, you can\n" +
              "administer this machine remotely from another machine. Use a RDP\n" +
              "client, such as rdesktop (connect to <tt>&lt;hostname&gt;:%1</tt>).\n" +
              "This form of remote administration is less secure than using SSH.</p>\n"
          ),
          3389
        ),
        firewall_help
      )

      # Remote Administration dialog contents
      contents = HBox(
        HStretch(),
        VBox(
          Frame(
            # Dialog frame title
            _("Remote Administration Settings"),
            allow_buttons
          ),
          VSpacing(1),
          Frame(
            # Dialog frame title
            _("Firewall Settings"),
            firewall_layout
          )
        ),
        HStretch()
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        help,
        Label.BackButton,
        Label.FinishButton
      )

      UI.ChangeWidget(Id(:allow), :Value, RDP.allow_administration)
      UI.ChangeWidget(Id(:disallow), :Value, !RDP.allow_administration)

      CWMFirewallInterfaces.OpenFirewallInit(firewall_widget, "")

      ret = nil
      event = nil
      begin
        event = UI.WaitForEvent
        ret = Ops.get(event, "ID")

        CWMFirewallInterfaces.OpenFirewallHandle(firewall_widget, "", event)

        if ret == :abort
          break
        elsif ret == :help
          Wizard.ShowHelp(help)
        elsif ret == :cancel
          break
        end
      end until ret == :next || ret == :back

      if ret == :next
        CWMFirewallInterfaces.OpenFirewallStore(firewall_widget, "", event)
        RDP.allow_administration = Convert.to_boolean(
          UI.QueryWidget(Id(:allow), :Value)
        )
      end

      Convert.to_symbol(ret)
    end
  end
end
