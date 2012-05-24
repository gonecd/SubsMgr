CXX=/usr/bin/g++-4.2

SHELL = /bin/sh

#### Start of system configuration section. ####

srcdir = .
topdir = /Users/olivier/.rbenv/versions/ree-1.8.7-2012.02/lib/ruby/1.8/i686-darwin11.4.0
hdrdir = $(topdir)
VPATH = $(srcdir):$(topdir):$(hdrdir)
exec_prefix = $(prefix)
prefix = $(DESTDIR)/Users/olivier/.rbenv/versions/ree-1.8.7-2012.02
datadir = $(datarootdir)
oldincludedir = $(DESTDIR)/usr/include
localedir = $(datarootdir)/locale
sysconfdir = $(prefix)/etc
vendorarchdir = $(vendorlibdir)/$(sitearch)
htmldir = $(docdir)
dvidir = $(docdir)
docdir = $(datarootdir)/doc/$(PACKAGE)
localstatedir = $(prefix)/var
sitelibdir = $(sitedir)/$(ruby_version)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
libexecdir = $(exec_prefix)/libexec
infodir = $(datarootdir)/info
datarootdir = $(prefix)/share
sitedir = $(libdir)/ruby/site_ruby
psdir = $(docdir)
sitearchdir = $(sitelibdir)/$(sitearch)
includedir = $(prefix)/include
vendorlibdir = $(vendordir)/$(ruby_version)
vendordir = $(libdir)/ruby/vendor_ruby
rubylibdir = $(libdir)/ruby/$(ruby_version)
libdir = $(exec_prefix)/lib
pdfdir = $(docdir)
sharedstatedir = $(prefix)/com
archdir = $(rubylibdir)/$(arch)
mandir = $(datarootdir)/man

CC = /usr/bin/gcc-4.2
LIBRUBY = $(LIBRUBY_A)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = 
LIBRUBYARG_STATIC = -l$(RUBY_SO_NAME)-static

RUBY_EXTCONF_H = 
CFLAGS   =  -fno-common -g -O2  -pipe -fno-common $(cflags) 
INCFLAGS = $(PREINCFLAGS) -I. -I/opt/local/include -I. -I/Users/olivier/.rbenv/versions/ree-1.8.7-2012.02/lib/ruby/1.8/i686-darwin11.4.0 -I.
DEFS     = 
CPPFLAGS =  -I'/Users/olivier/.rbenv/versions/ree-1.8.7-2012.02/include'  -D_XOPEN_SOURCE -D_DARWIN_C_SOURCE  -I'/Users/olivier/.rbenv/versions/ree-1.8.7-2012.02/include' 
CXXFLAGS = $(CFLAGS) 
ldflags  = -L. -L'/Users/olivier/.rbenv/versions/ree-1.8.7-2012.02/lib' 
dldflags = 
archflag = 
DLDFLAGS = $(ldflags) $(dldflags) $(archflag)
LDSHARED = cc -dynamic -bundle -undefined suppress -flat_namespace
AR = ar
EXEEXT = 

RUBY_INSTALL_NAME = ruby
RUBY_SO_NAME = ruby
arch = i686-darwin11.4.0
sitearch = i686-darwin11.4.0
ruby_version = 1.8
ruby = /Users/olivier/.rbenv/versions/ree-1.8.7-2012.02/bin/ruby
RUBY = $(ruby)
RM = rm -f
MAKEDIRS = mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp

#### End of system configuration section. ####

preload = 

libpath = . $(libdir)
LIBPATH =  -L. -L$(libdir)
DEFFILE = 

CLEANFILES = mkmf.log
DISTCLEANFILES = 

extout = 
extout_prefix = 
target_prefix = 
LOCAL_LIBS = 
LIBS =  -lstdc++  -L/opt/local/lib -ldl -lobjc  
SRCS = unf.cc
OBJS = unf.o
TARGET = unf_ext
DLLIB = $(TARGET).bundle
EXTSTATIC = 
STATIC_LIB = 

BINDIR        = $(bindir)
RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR = /Users/olivier/Git/subsmgr/vendor/bundle/ruby/1.8/gems/unf_ext-0.0.4/lib$(target_prefix)
RUBYARCHDIR = /Users/olivier/Git/subsmgr/vendor/bundle/ruby/1.8/gems/unf_ext-0.0.4/lib$(target_prefix)

TARGET_SO     = $(DLLIB)
CLEANLIBS     = $(TARGET).bundle $(TARGET).il? $(TARGET).tds $(TARGET).map
CLEANOBJS     = *.o *.a *.s[ol] *.pdb *.exp *.bak

all:		$(DLLIB)
static:		$(STATIC_LIB)

clean:
		@-$(RM) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES)

distclean:	clean
		@-$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		@-$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)

realclean:	distclean
install: install-so install-rb

install-so: $(RUBYARCHDIR)
install-so: $(RUBYARCHDIR)/$(DLLIB)
$(RUBYARCHDIR)/$(DLLIB): $(DLLIB)
	$(INSTALL_PROG) $(DLLIB) $(RUBYARCHDIR)
install-rb: pre-install-rb install-rb-default
install-rb-default: pre-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
$(RUBYARCHDIR):
	$(MAKEDIRS) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .cxx .cpp .C .o

.cc.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cxx.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cpp.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.C.o:
	$(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.c.o:
	$(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -c $<

$(DLLIB): $(OBJS) Makefile
	@-$(RM) $@
	$(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)



$(OBJS): ruby.h defines.h
