# encoding: utf-8

# File:	src/modules/RDP.ycp
# Module:	Network configuration
# Summary:	Module for Remote Administration via RDP
# Authors:	Arvin Schnell <arvin@suse.de>
#		Martin Vidner <mvidner@suse.cz>
#		David Reveman <davidr@novell.com>
#
require "yast"
require "y2firewall/firewalld"

module Yast
  class RDPClass < Module
    FW_ZONES = ["public", "external", "internal", "work", "home", "trusted"].freeze
    # Use firewalld remote desktop service
    FW_SERVICE = "ms-wbt".freeze
    def main
      Yast.import "UI"
      textdomain "rdp"

      Yast.import "Label"
      Yast.import "Mode"
      Yast.import "Package"
      Yast.import "PackageSystem"
      Yast.import "Service"
      Yast.import "Progress"
      Yast.import "Linuxrc"

      # Allow remote administration
      @allow_administration = false

      # Remote administration has been already proposed
      # Only force-reset can change it
      @already_proposed = false

      # True only if the port is open in all firewall zones
      @open_fw_port = false
    end

    attr_accessor(:open_fw_port, :allow_administration)

    def firewalld
      Y2Firewall::Firewalld.instance
    end

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

      firewalld.read
      @open_fw_port = firewalld.zones.any? { |z| z.services.include?(FW_SERVICE) }
      true
    end

    # Update the SCR according to network settings
    # @return true on success
    def Write
      start_write_progress
      Progress.NextStage
      write_firewall_settings

      sl = 0 #100; //for testing
      Builtins.sleep(sl)
      Progress.NextStage
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
        Progress.NextStage
        @allow_administration ? Service.Restart("xrdp") : Service.Stop("xrdp")

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

    # Modify the firewall modifications if it is installed and the zones are
    # available
    def write_firewall_settings
      return unless firewalld.installed?
      FW_ZONES.each do |name|
        zone = firewalld.find_zone(name)
        unless zone
          Builtins.y2error("Firewalld zone #{name} is not available.")
          next
        end
        @open_fw_port ? zone.add_service(FW_SERVICE) : zone.remove_service(FW_SERVICE)
      end
      firewalld.write
    end

    publish :function => :Reset, :type => "void ()"
    publish :function => :Propose, :type => "void ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Summary, :type => "string ()"

  private

    # Convenience method to show the write progress dialog
    def start_write_progress
      caption = _("Saving Remote Administration (RDP) Configuration")

      steps = progress_write_steps.map {|s| s[:step] }
      titles = progress_write_steps.map {|s| s[:title] }
      Progress.New(caption, " ", steps.size, steps, titles, "")
    end

    # Convenience method to obtain the write progress steps and titles
    # descriptions
    #
    # @return [Array<Hash<Symbol, String>>] all the steps descriptions
    def progress_write_steps
      steps = []
      steps << { step: _("Write firewall settings"), title: _("Writing firewall settings...") }
      steps << { step: _("Configure xrdp"), title: _("Configuring xrdp...") }
      steps << write_service_step if Mode.normal
      steps
    end

    # Return the rpd service progress step description
    #
    # @return [Hash<Symbol, String>]
    def write_service_step
      if @allow_administration
        { step: _("Restart the services"), title: _("Restarting the service...") }
      else
        { step: _("Stop the services"), title: _("Stopping the service...") }
      end
    end
  end

  RDP = RDPClass.new
  RDP.main
end
