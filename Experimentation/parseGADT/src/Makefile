# Makefile generated by BNFC.

# List of goals not corresponding to file names.

.PHONY : all clean distclean

# Default goal.

all : TestLang

# Rules for building the parser.

ErrM.hs LexLang.x PrintLang.hs ParLang.y TestLang.hs : lang.bnfc
	bnfc --haskell-gadt lang.bnfc

%.hs : %.y
	happy --ghc --coerce --array --info $<

%.hs : %.x
	alex --ghc $<

TestLang : TestLang.hs ErrM.hs LexLang.hs ParLang.hs PrintLang.hs
	ghc --make $< -o $@

# Rules for cleaning generated files.

clean :
	-rm -f *.hi *.o *.log *.aux *.dvi

distclean : clean
	-rm -f AbsLang.hs AbsLang.hs.bak ComposOp.hs ComposOp.hs.bak DocLang.txt DocLang.txt.bak ErrM.hs ErrM.hs.bak LayoutLang.hs LayoutLang.hs.bak LexLang.x LexLang.x.bak ParLang.y ParLang.y.bak PrintLang.hs PrintLang.hs.bak SharedString.hs SharedString.hs.bak SkelLang.hs SkelLang.hs.bak TestLang.hs TestLang.hs.bak XMLLang.hs XMLLang.hs.bak ASTLang.agda ASTLang.agda.bak ParserLang.agda ParserLang.agda.bak IOLib.agda IOLib.agda.bak Main.agda Main.agda.bak lang.dtd lang.dtd.bak TestLang LexLang.hs ParLang.hs ParLang.info ParDataLang.hs Makefile


# EOF
