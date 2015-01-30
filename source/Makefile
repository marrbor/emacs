include ../Makefile.leaf

INSTALL:=$(SUDO) make install EMACS=$(EMACS)
INSTALL_W3M:=$(SUDO) make install-lisp EMACS=$(EMACS) lispdir=$(SITELISP)/w3m

all: apel skk w3m

skk: $(SHAREDIR)/skk $(VERSITELISP)/skk
w3m: apel $(SITELISP)/w3m
apel: $(SITELISP)/apel

arc2dir=$(subst .tar.gz,,$(1))
dir2arg=$(addsuffix .tar.gz,$(1))

# skk
SKKARC:=$(shell $(FIND) . -name 'ddskk*.tar.gz')
SKKDIR:=$(call arc2dir,$(SKKARC))
$(SHAREDIR)/skk: $(SKKARC)
	tar -zxf $(SKKARC)
	cd $(SKKDIR) && $(INSTALL)

$(VERSITELISP)/skk: $(SKKARC)
	tar -zxf $(SKKARC)
	cd $(SKKDIR) && $(INSTALL)

# w3m
W3MARC:=$(shell $(FIND) . -name 'emacs-w3m*.tar.gz')
W3MDIR:=$(call arc2dir,$(W3MARC))
$(SITELISP)/w3m: $(W3MARC)
	tar -zxf $(W3MARC)
	cd $(W3MDIR) && ./configure --with-emacs=$(EMACS) && $(INSTALL_W3M)

# apel
$(SITELISP)/apel: ./apel
	cd $< && sudo make install

./apel:
	git clone https://github.com/wanderlust/apel

test:
	@echo "PREFIX:$(PREFIX)"
	@echo "SKKDIR:$(SKKDIR)"
	@echo "W3MDIR:$(W3MDIR)"
	@echo "SHAREDIR:$(SHAREDIR)"
