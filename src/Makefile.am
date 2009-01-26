# Makefile.am for rdp/src

yncludedir = @yncludedir@/rdp

client_DATA =			\
	rdp.ycp		\
	rdp_proposal.ycp

ynclude_DATA =			\
	dialogs.ycp

desktop_DATA =			\
	rdp.desktop

module_DATA =			\
	RDP.ycp

# create a symlink for local build, #145327
rdp:
	ln -sf . $@
ycpchook = rdp

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
