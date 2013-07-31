# encoding: utf-8

module Yast
  class RdpClient < Client
    def main
      # testedfiles: RDP.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "RDP"

      DUMP("RDP::Modified") 
      #TEST(``(RDP::Modified()), [], nil);

      nil
    end
  end
end

Yast::RdpClient.new.main
