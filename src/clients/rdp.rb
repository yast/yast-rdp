# encoding: utf-8

# File:	clients/rdp.ycp
# Package:	Network configuration
# Summary:	Remote Administration
# Authors:	Arvin Schnell <arvin@suse.de>
#		Michal Svec <msvec@suse.cz>
#		David Reveman <davidr@novell.com>
module Yast
  class RdpClient < Client
    def main
      Yast.import "UI"

      textdomain "rdp"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("RDP module started")

      Yast.import "Label"
      Yast.import "RDP"
      Yast.import "Wizard"
      Yast.import "Report"

      Yast.import "CommandLine"
      Yast.import "RichText"

      Yast.include self, "rdp/dialogs.rb"

      # Command line definition
      @cmdline = {
        # Commandline help title
        "help"       => _(
          "Remote Access Configuration"
        ),
        "id"         => "rdp",
        "guihandler" => fun_ref(method(:RemoteGUI), "any ()"),
        "initialize" => fun_ref(RDP.method(:Read), "boolean ()"),
        "finish"     => fun_ref(RDP.method(:Write), "boolean ()"),
        "actions"    => {
          "list"  => {
            # Commandline command help
            "help"    => _(
              "Display configuration summary"
            ),
            "handler" => fun_ref(
              method(:ListHandler),
              "boolean (map <string, string>)"
            )
          },
          "allow" => {
            # Commandline command help
            "help"    => _("Allow remote access"),
            "handler" => fun_ref(
              method(:SetRAHandler),
              "boolean (map <string, string>)"
            ),
            "example" => ["allow set=yes", "allow set=no"]
          }
        },
        "options"    => {
          "set" => {
            # Commandline command help
            "help" => _(
              "Set 'yes' to allow or 'no' to disallow the remote administration"
            ),
            "type" => "string"
          }
        },
        "mappings"   => { "allow" => ["set"] }
      }

      @ret = CommandLine.Run(@cmdline)
      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("RDP module finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end

    # Main remote GUI
    def RemoteGUI
      RDP.Read

      Wizard.CreateDialog
      Wizard.SetDesktopIcon("org.openSUSE.YaST.RDP")
      Wizard.SetNextButton(:next, Label.FinishButton)

      ret = RemoteMainDialog()
      RDP.Write if ret == :next

      UI.CloseDialog
      deep_copy(ret)
    end

    # Handler for action "list"
    # @param [Hash{String => String}] options action options
    def ListHandler(options)
      options = deep_copy(options)
      summary = ""
      # Command line output Headline
      summary = Ops.add(
        Ops.add(
          "\n" + _("Remote Access Configuration Summary:") + "\n\n",
          RichText.Rich2Plain(RDP.Summary)
        ),
        "\n"
      )

      Builtins.y2debug("%1", summary)
      CommandLine.Print(summary)
      true
    end

    # Handler for action "allow"
    # @param [Hash{String => String}] options action options
    def SetRAHandler(options)
      options = deep_copy(options)
      allow_ra = Builtins.tolower(Ops.get(options, "set", ""))

      if allow_ra != "yes" && allow_ra != "no"
        # Command line error message
        Report.Error(
          _(
            "Please set 'yes' to allow the remote administration\nor 'no' to disallow it."
          )
        )
        return false
      end

      Builtins.y2milestone(
        "Setting AllowRemoteAdministration to '%1'",
        allow_ra
      )
      RDP.allow_administration = allow_ra == "yes" ? true : false

      true
    end
  end
end

Yast::RdpClient.new.main
