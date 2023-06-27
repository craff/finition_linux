all: cntlm debs

.PHONY: cntlm
cntlm:
	if [ ! -d cntlm ] ; then \
	  git clone https://github.com/craff/cntlm ; \
	fi
	cd cntlm; git pull; ./configure; make -j 4

.PHONY: debs
debs:
	cd debs; wget -nc https://github.com/jgraph/drawio-desktop/releases/download/v21.5.0/drawio-amd64-21.5.0.deb

	cd debs; wget -nc https://www.lernsoftware-filius.de/downloads/Setup/filius_2.4.1_all.deb

	cd debs; wget -nc https://github.com/shiftkey/desktop/releases/download/release-3.2.1-linux1/GitHubDesktop-linux-3.2.1-linux1.deb

.PHONY: clean
clean:
	cd cntlm
	make clean

.PHONY: distclean
distclean:
	- rm -rf cntlm
	- rm debs/*
