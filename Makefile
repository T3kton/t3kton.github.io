.PHONY: copy
copy:
	rsync -av --delete --exclude .git --exclude .buildinfo --exclude objects.inv --exclude .nojekyll --exclude Makefile --exclude README.rst build build/html/ .


