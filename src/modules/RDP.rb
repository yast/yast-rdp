# encoding: utf-8

# File:	src/modules/RDP.ycp
# Module:	Network configuration
# Summary:	Module for Remote Administration via RDP
# Authors:	Arvin Schnell <arvin@suse.de>
#		Martin Vidner <mvidner@suse.cz>
#		David Reveman <davidr@novell.com>
#
require "yast"

module Yast
  class RDPClass < Module
    def main
      Yast.import "UI"
      textdomain "rdp"

      Yast.import "Label"
      Yast.import "Mode"
      Yast.import "Package"
      Yast.import "PackageSystem"
      Yast.import "Service"
      Yast.import "SuSEFirewall"
      Yast.import "Progress"
      Yast.import "Linuxrc"

      Yast.include self, "network/routines.rb"

      # Allow remote administration
      @allow_administration = false

      # Remote administration has been already proposed
      # Only force-reset can change it
      @already_proposed = false

      # True only if the port is open in all firewall zones
      @open_fw_port = false
    end
    
    attr_accessor(:open_fw_port, :allow_administration)

    # Reset all module data.
    def Reset
      @already_proposed = true

      @allow_administration = true
      @open_fw_port = true
      Builtins.y2milestone(
        "Remote Administration was proposed as: %1",
        @allow_administration ? "enabled" : "disabled"
      )

      nil
    end

    # Function proposes a configuration
    # But only if it hasn't been proposed already
    def Propose
      Reset() if !@already_proposed

      nil
    end

    # Read the current status
    # @return true on success
    def Read
      packages = ["xrdp"]

      if !PackageSystem.CheckAndInstallPackagesInteractive(packages)
        Builtins.y2error("Installing of required packages failed")
        return false
      end

      xrdp = Service.Enabled("xrdp")

      Builtins.y2milestone("xrdp: %1", xrdp)
      @allow_administration = xrdp

      current_progress = Progress.set(false)
      SuSEFirewall.Read
      Progress.set(current_progress)
      @open_fw_port = SuSEFirewall.IsServiceDefinedByPackageSupportedInZone('service:xrdp', 'EXT') &&
                      SuSEFirewall.IsServiceDefinedByPackageSupportedInZone('service:xrdp', 'INT')
      true
    end

    # Update the SCR according to network settings
    # @return true on success
    def Write
      steps = [
        # Progress stage 1
        _("Write firewall settings"),
        # Progress stage 2
        _("Configure xrdp")
      ]

      if Mode.normal
        # Progress stage 3
        if @allow_administration
          steps = Builtins.add(steps, _("Restart the services"))
        else
          steps = Builtins.add(steps, _("Stop the services"))
        end
      end

      caption = _("Saving Remote Administration (RDP) Configuration")
      sl = 0 #100; //for testing

      Progress.New(caption, " ", Builtins.size(steps), steps, [], "")

      ProgressNextStage(_("Writing firewall settings..."))
      current_progress = Progress.set(false)

      if @open_fw_port
          SuSEFirewall.AddServiceDefinedByPackageIntoZone("service:xrdp", "EXT")
          SuSEFirewall.AddServiceDefinedByPackageIntoZone("service:xrdp", "INT")
      else
          SuSEFirewall.RemoveServiceDefinedByPackageFromZone("service:xrdp", "EXT")
          SuSEFirewall.RemoveServiceDefinedByPackageFromZone("service:xrdp", "INT")
      end
      SuSEFirewall.Write
      Progress.set(current_progress)
      Builtins.sleep(sl)

      ProgressNextStage(_("Configuring xrdp..."))

      if @allow_administration
        # Enable xrdp
        if !Service.Enable("xrdp")
          Builtins.y2error("Enabling of xrdp failed")
          return false
        end
      else
        # Disable xrdp
        if !Service.Disable("xrdp")
          Builtins.y2error("Disabling of xrdp failed")
          return false
        end
      end
      Builtins.sleep(sl)

      if Mode.normal
        if @allow_administration
          ProgressNextStage(_("Restarting the service..."))
          Service.Restart("xrdp")
        else
          ProgressNextStage(_("Stopping the service..."))
          Service.Stop("xrdp")
        end

        Builtins.sleep(sl)
        Progress.NextStage
      end

      true
    end

    # Create summary
    # @return summary text
    def Summary
      if @allow_administration
        # Label in proposal text
        return _("RDP (remote desktop protocol) service is enabled.")
      else
        # Label in proposal text
        return _("RDP (remote desktop protocol) service is disabled.")
      end
    end

    publish :function => :Reset, :type => "void ()"
    publish :function => :Propose, :type => "void ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Summary, :type => "string ()"
  end

  RDP = RDPClass.new
  RDP.main
end
