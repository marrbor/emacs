include ../Makefile.leaf

ROOT:=.
ELISPS:=$(shell $(FIND) $(ROOT) -name '*.el')
EXCEPTS:=csharp-mode nsis-mode hiki-mode
EXFILES:=$(addprefix $(ROOT)/,$(addsuffix .el,$(EXCEPTS)))
ELCS:=$(addsuffix c,$(filter-out $(EXFILES), $(ELISPS)))
LISPPATH:=$(ROOT)

all:$(ELCS)

%.elc: %.el
	-$(EMACS) -Q -batch -L $(LISPPATH) -f batch-byte-compile $<

clean:
	rm -f $(ELCS)

test:
	@echo "ELISPS:$(ELISPS)"
	@echo "ELCS:$(ELCS)"
