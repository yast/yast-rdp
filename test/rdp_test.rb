require_relative "test_helper"
require "y2firewall/firewalld"

Yast.import "RDP"

describe "Yast::RDP" do
  subject { Yast::RDP }
  let(:firewalld) { Y2Firewall::Firewalld.instance }
  let(:firewalld_installed) { false }
  let(:zones) { Yast::RDPClass::FW_ZONES.map { |z| Y2Firewall::Firewalld::Zone.new(name: z) } }

  before do
    allow(subject).to receive(:firewalld).and_return(firewalld)
    allow(firewalld).to receive(:installed?).and_return(firewalld_installed)
    allow(firewalld).to receive(:write)
    allow(firewalld).to receive(:zones).and_return(zones)
    zones.each do |z|
      allow(z).to receive(:add_service).with(Yast::RDPClass::FW_SERVICE)
      allow(z).to receive(:remove_service).with(Yast::RDPClass::FW_SERVICE)
    end
  end

  describe "#write_firewall_settings" do
    context "when the firewall is not installed" do
      it "returns nil" do
        expect(firewalld).to_not receive(:write)

        expect(subject.write_firewall_settings).to eq(nil)
      end
    end

    context "when the firewall is installed" do
      let(:firewalld_installed) { true }

      context "and the service is set to be opened" do
        it "opens the service in all the zones" do
          subject.open_fw_port = true
          zones.each do |zone|
            expect(zone).to receive(:add_service).with(Yast::RDPClass::FW_SERVICE)
          end
          expect(subject.write_firewall_settings)
        end
        it "writes the modifed configuration" do
          expect(firewalld).to receive(:write)

          subject.write_firewall_settings
        end
      end

      context "and the service is not set to be opened" do
        it "removes the service from all the zones" do
          subject.open_fw_port = false
          zones.each do |zone|
            expect(zone).to receive(:remove_service).with(Yast::RDPClass::FW_SERVICE)
          end
          expect(subject.write_firewall_settings)
        end

        it "writes the modifed configuration" do
          expect(firewalld).to receive(:write)

          subject.write_firewall_settings
        end
      end
    end
  end
end
