include Makefile.leaf

DIRS:=fonts libs/ditaa

all: $(DIRS)

.PHONY : $(DIRS)

$(DIRS):
ifeq ($(strip $(EMACS)),)
	$(error "cannot find emacs.")
else
ifeq ($(strip $(AUTOCONF)),)
	$(error "cannot find autoconf.")
endif
endif
	-cd $@ && make

lisp: source

test:
	@echo "EMACS:$(EMACS)"
	@echo "EMACSVER:$(EMACSVER)"
	@echo "DIRS:$(DIRS)"
