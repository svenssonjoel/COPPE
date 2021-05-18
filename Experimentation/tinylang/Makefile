all:
	happy -gca ParTinylang.y
	alex -g LexTinylang.x
	ghc --make TestTinylang.hs -o TestTinylang

clean:
	-rm -f *.log *.aux *.hi *.o *.dvi

distclean: clean
	-rm -f DocTinylang.* LexTinylang.* ParTinylang.* LayoutTinylang.* SkelTinylang.* PrintTinylang.* TestTinylang.* AbsTinylang.* TestTinylang ErrM.* SharedString.* ComposOp.* tinylang.dtd XMLTinylang.* Makefile*
	

