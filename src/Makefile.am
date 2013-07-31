# Sources for rdp

module_DATA = \
  modules/RDP.rb

client_DATA = \
  clients/rdp_proposal.rb \
  clients/rdp.rb

yncludedir = @yncludedir@/rdp
ynclude_DATA = \
  include/rdp/dialogs.rb

desktop_DATA = \
  desktop/rdp.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common